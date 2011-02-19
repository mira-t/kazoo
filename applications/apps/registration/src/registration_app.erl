%%% @author James Aimonetti <james@2600hz.org>
%%% @copyright (C) 2011 James Aimonetti
%%% @doc
%%% 
%%% @end
%%% Created :  Thu, 13 Jan 2011 22:12:40 GMT: James Aimonetti <james@2600hz.org>
-module(registration_app).

-behaviour(application).

-include("reg.hrl").

%% Application callbacks
-export([start/2, stop/1, setup_views/0, update_views/0]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

-spec(start/2 :: (StartType :: term(), StartArgs :: term()) -> tuple(ok, pid()) | tuple(error, term())).
start(_StartType, _StartArgs) ->
    setup_views(),
    case registration:start_link() of
	{ok, P} -> {ok, P};
	{error, {already_started, P} } -> {ok, P};
	{error, _}=E -> E
    end.

stop(_State) ->
    ok.

setup_views() ->
    lists:foreach(fun({DB, File}) ->
			  couch_mgr:load_doc_from_file(DB, registration, File)
		  end, ?JSON_FILES).

update_views() ->
    lists:foreach(fun({DB, File}) ->
			  couch_mgr:update_doc_from_file(DB, registration, File)
		  end, ?JSON_FILES).
