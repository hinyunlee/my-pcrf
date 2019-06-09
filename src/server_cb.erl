% PCRF Behavior
-module(server_cb).

-include_lib("config.hrl").
-include_lib("diameter/include/diameter.hrl").
-include_lib("dict/diameter_3gpp_gx.hrl").

-define(APP_ID_3GPP_GX, 16777238).

-export([peer_up/3,
         peer_down/3,
         pick_peer/4,
         prepare_request/3,
         prepare_retransmit/3,
         handle_answer/4,
         handle_error/4,
         handle_request/3]).

peer_up(_SvcName, _Peer, State) ->
    State.

peer_down(_SvcName, _Peer, State) ->
    State.

pick_peer([Peer | _], _RemoteCandidates, _SvcName, _State) ->
    {ok, Peer}.

prepare_request(Packet, _SvcName, _Peer) ->
    {send, Packet}.

prepare_retransmit(Packet, SvcName, Peer) ->
    prepare_request(Packet, SvcName, Peer).

handle_answer(#diameter_packet{msg = Ans}, _Request, _SvcName, _Peer)
  when is_record(Ans, 'diameter_3gpp_gx_RA-Answer') ->
    #'diameter_3gpp_gx_RA-Answer'{
        'Session-Id' = SessionId} = Ans,
    io:fwrite("Received RAA for ~s~n", [SessionId]),
    % Confidential information removed
    {ok, Ans}.

handle_error(Reason, _Request, _SvcName, _Peer) ->
    {error, Reason}.

handle_request(#diameter_packet{msg = Req, errors = []}, _SvcName, Peer)
  when is_record(Req, 'diameter_3gpp_gx_CC-Request') ->
    handle_ccr(Req, Peer);

handle_request(#diameter_packet{msg = Req, errors = Err}, _SvcName, Peer)
  when is_record(Req, 'diameter_3gpp_gx_CC-Request') ->
    io:fwrite("~p~n", [Err]),
    {reply, init_cca(Req, [3001], Peer)};

handle_request(_, _, _) ->
    discard.

handle_ccr(Req, Peer) ->
    #'diameter_3gpp_gx_CC-Request'{
        'Session-Id' = SessionId,
        'Origin-Host' = Host,
        'Origin-Realm' = Realm,
        'CC-Request-Type' = ReqType,
        'Subscription-Id' = [
            #'diameter_3gpp_gx_Subscription-Id'{
                'Subscription-Id-Data' = SubscriptionIdData}],
        'Charging-Rule-Report' = ChargingRuleReport} = Req,
    SessionPid = spawn(fun() -> 
        Res = case ReqType of
            ?'DIAMETER_3GPP_GX_CC-REQUEST-TYPE_INITIAL_REQUEST' ->
                session_db:init_session(SessionId, SubscriptionIdData);
            ?'DIAMETER_3GPP_GX_CC-REQUEST-TYPE_UPDATE_REQUEST' ->
                ok;
            ?'DIAMETER_3GPP_GX_CC-REQUEST-TYPE_TERMINATION_REQUEST' ->
                session_db:terminate_session(SessionId)
        end,
        receive
            result -> Res
        end
    end),
    Ans = init_cca(Req, [2001], Peer),
    RuleFailureCode = get_rule_failure_code(ChargingRuleReport),
    Action = case ReqType of
        X when X == ?'DIAMETER_3GPP_GX_CC-REQUEST-TYPE_INITIAL_REQUEST';
               X == ?'DIAMETER_3GPP_GX_CC-REQUEST-TYPE_UPDATE_REQUEST' ->
            case RuleFailureCode of
                not_found -> 
                    {reply, Ans#'diameter_3gpp_gx_CC-Answer'{
                        'Event-Trigger' = [?'DIAMETER_3GPP_GX_EVENT-TRIGGER_USAGE_REPORT'],
                        'Usage-Monitoring-Information' = [get_usage_monitoring_information(SubscriptionIdData)],
                        'Charging-Rule-Install' = get_charging_rule_installs(SubscriptionIdData)}};
                {found, Code} ->
                    io:fwrite("Received CCR for ~s with Rule-Failure-Code ~p~n", [SessionId, Code]),
                    {reply, Ans#'diameter_3gpp_gx_CC-Answer'{
                        'Event-Trigger' = [?'DIAMETER_3GPP_GX_EVENT-TRIGGER_USAGE_REPORT'],
                        'Usage-Monitoring-Information' = [get_usage_monitoring_information(SubscriptionIdData)]}}
                        % Confidential information removed
            end;
        ?'DIAMETER_3GPP_GX_CC-REQUEST-TYPE_TERMINATION_REQUEST' ->
            {reply, Ans}
    end,
    SessionPid ! result,
    Action.

init_cca(Req, ResultCode, {_, Caps}) ->
    #diameter_caps{
        origin_host = {OriginHost, _},
        origin_realm = {OriginRealm, _}} = Caps,
    #'diameter_3gpp_gx_CC-Request'{
        'Session-Id' = SessionId,
        'CC-Request-Type' = ReqType,
        'CC-Request-Number' = ReqNum,
        'Usage-Monitoring-Information' = UsageMonitoringInfo} = Req,
    #'diameter_3gpp_gx_CC-Answer'{
        'Session-Id' = SessionId,
        'Auth-Application-Id' = ?APP_ID_3GPP_GX,
        'Origin-Host' = OriginHost,
        'Origin-Realm' = OriginRealm,
        'Result-Code' = ResultCode,
        'CC-Request-Type' = ReqType,
        'CC-Request-Number' = ReqNum,
        'Usage-Monitoring-Information' = UsageMonitoringInfo}.

get_usage_monitoring_information(SubscriptionId) ->
    #'diameter_3gpp_gx_Usage-Monitoring-Information'{
        % Confidential information removed
        'Usage-Monitoring-Level' = [?'DIAMETER_3GPP_GX_USAGE-MONITORING-LEVEL_SESSION_LEVEL']}.

get_charging_rule_installs(SubscriptionId) ->
    % Confidential information removed
    todo.

% Get from Charging-Rule-Report list
get_rule_failure_code([X | Xs]) ->
    case X of
        #'diameter_3gpp_gx_Charging-Rule-Report'{'Rule-Failure-Code' = RuleFailureCode} ->
            {found, RuleFailureCode};
        _ ->
            get_rule_failure_code(Xs)
    end;

get_rule_failure_code([]) ->
    not_found.
