%%%-------------------------------------------------------------------
%%% @author Karl Anderson <karl@2600hz.org>
%%% @copyright (C) 2011, Karl Anderson
%%% @doc
%%%
%%% @end
%%% Created : 22 Feb 2011 by Karl Anderson <karl@2600hz.org>
%%%-------------------------------------------------------------------
-module(cf_device).

-include("../callflow.hrl").

-export([handle/2]).

-import(cf_call_command, [b_bridge/6, wait_for_bridge/1, wait_for_unbridge/0, set/3, b_fetch/2]).

%%--------------------------------------------------------------------
%% @public
%% @doc
%% Entry point for this module, attempts to call an endpoint as defined
%% in the Data payload.  Returns continue if fails to connect or 
%% stop when successfull.
%% @end
%%--------------------------------------------------------------------
-spec(handle/2 :: (Data :: json_object(), Call :: #cf_call{}) -> tuple(stop | continue)).
handle(Data, #cf_call{cf_pid=CFPid, call_id=CallId}=Call) ->    
    put(callid, CallId),
    Id = wh_json:get_value(<<"id">>, Data),
    ?LOG("loading endpoint ~s", [Id]),
    {ok, Endpoint} = cf_endpoint:build(Id, Call),
    Timeout = wh_json:get_value(<<"timeout">>, Data, ?DEFAULT_TIMEOUT),  
    IgnoreEarlyMedia = wh_json:get_value(<<"Ignore-Early-Media">>, Endpoint),
    case b_bridge([Endpoint], Timeout, {undefined, undefined}, <<"single">>, IgnoreEarlyMedia, Call) of
        {ok, _} ->
            ?LOG("bridged to endpoint"),
            update_call_realm(Call),
            _ = wait_for_unbridge(),
            ?LOG("bridge completed"),
            CFPid ! { stop };
        {error, {bridge_failed, R}} ->
            ?LOG("failed to bridge to endpoint ~s", [R]),
            CFPid ! { continue };
        {error, R} ->
            ?LOG("failed to bridge to endpoint ~w", [R]),
            CFPid ! { continue }
    end.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% When the bridge is successfull this is used to set the realm of 
%% the endpoint on the a-leg.  This is necessary, for example, in 
%% blind transfers to external numbers where the a-leg is seen
%% as the 'orginator'. 
%% @end
%%--------------------------------------------------------------------
-spec(update_call_realm/1 :: (Call :: #cf_call{}) -> no_return()).
update_call_realm(Call) ->
    case b_fetch(true, Call) of
        {error, _} ->
            ok;
        {ok, undefined} ->
            ok;
        {ok, Vars} ->
            case wh_json:get_value(<<"Realm">>, Vars) of 
                undefined -> ok;
                <<>> -> ok;
                Realm -> set(undefined, {struct, [{<<"Realm">>, Realm}]}, Call)
            end
    end.
