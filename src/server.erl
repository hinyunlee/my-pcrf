% PCRF Interface
-module(server).

-include_lib("config.hrl").
-include_lib("diameter/include/diameter.hrl").
-include_lib("dict/diameter_3gpp_gx.hrl").

-define(SERVICE_NAME, 'my-pcrf').
-define(APP_ID_3GPP_GX, 16777238).
-define(VENDOR_ID_3GPP, 10415).
-define(DIAMETER_PORT, 3868).

-export([start/0, stop/0, reauth/2]).

% Network interface name to IP address
if_to_addr(Name) ->
    {ok, Addrs} = inet:getifaddrs(),
    Opt = proplists:get_value(Name, Addrs),
    proplists:get_value(addr, Opt).

start() ->
    ServiceOpts = [
        {'Origin-Host', ?ORIGIN_HOST},
        {'Origin-Realm', ?ORIGIN_REALM},
        {'Vendor-Id', 0},
        {'Product-Name', "My PCRF"},
        {'Supported-Vendor-Id', [?VENDOR_ID_3GPP]},
        {'Auth-Application-Id', [?APP_ID_3GPP_GX]},
        {application, [
            {alias, gx},
            {dictionary, diameter_3gpp_gx},
            {module, server_cb}]}],
    TransportOpts = [
        {transport_module, diameter_tcp},
        {transport_config, [
            {reuseaddr, true},
            {ip, if_to_addr(?INTERFACE_NAME)},
            {port, ?DIAMETER_PORT}]}],
    ok = odbc:start(),
    ok = diameter:start(),
    ok = diameter:start_service(?SERVICE_NAME, ServiceOpts),
    {ok, _} = diameter:add_transport(?SERVICE_NAME, {listen, TransportOpts}),
    ok.

stop() ->
    diameter:stop_service(?SERVICE_NAME).

get_charging_rule_removes(Rules) ->
    % Confidential information removed
    todo.

get_charging_rule_installs(Rules) ->
    % Confidential information removed
    todo.

reauth_session(SessionId, Host, Realm, Rules) ->
    Req = #'diameter_3gpp_gx_RA-Request'{
        'Session-Id' = SessionId,
        'Auth-Application-Id' = ?APP_ID_3GPP_GX,
        'Origin-Host' = ?ORIGIN_HOST,
        'Origin-Realm' = ?ORIGIN_REALM,
        'Destination-Host' = Host,
        'Destination-Realm' = Realm,
        'Re-Auth-Request-Type' = ?'DIAMETER_3GPP_GX_RE-AUTH-REQUEST-TYPE_AUTHORIZE_ONLY',
        'Charging-Rule-Remove' = get_charging_rule_removes(Rules),
        'Charging-Rule-Install' = get_charging_rule_installs(Rules)},
    % Confidential information removed
    diameter:call(?SERVICE_NAME, gx, Req, [{filter, {all, [host, realm]}}, detach]).

reauth(SubscriptionId, Rules) ->
    % Confidential information removed
    todo.
