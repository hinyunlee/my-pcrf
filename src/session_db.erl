-module(session_db).

-include_lib("config.hrl").

-export([init_session/2,
         terminate_session/1]).

init_session(SessionId, SubscriptionId) ->
    {ok, Ref} = odbc:connect("DSN=" ++ ?ODBC_DSN, []),
    Stmt = "CALL init_session(\"" ++ SessionId ++ "\",\"" ++ SubscriptionId ++"\")",
    odbc:sql_query(Ref, Stmt),
    odbc:disconnect(Ref),
    ok.

terminate_session(SessionId) ->
    {ok, Ref} = odbc:connect("DSN=" ++ ?ODBC_DSN, []),
    Stmt = "CALL terminate_session(\"" ++ SessionId ++ "\")",
    odbc:sql_query(Ref, Stmt),
    odbc:disconnect(Ref),
    ok.

% Confidential information removed
