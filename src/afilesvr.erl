
%% OK. And it serves itself a unit test
%% %%%%%%%%%%
%% Revive. Restart. Reborn.

-module(afilesvr).
-export([start/1, serve_dir/1, test/0]).

-include_lib("eunit/include/eunit.hrl").

start(Dir)->
	spawn(afilesvr, serve_dir, [Dir]).

serve_dir(Dir)->
	receive 
		{Client, list_dir}->
			Client ! {self(), file:list_dir(Dir)};
		{Client, {get_file, File}}->
			Full = filename:join(Dir,File)
			%,io:format("Full is ~p~n", [Full])
			,Client ! {self(), file:read_file(Full)}
	end,
	serve_dir(Dir).

test()->
	Svr = start("."),
	Svr ! {self(), list_dir},
	receive {_, {ok, List}}->
		goTest1(Svr, List)
	end.

goTest1(Svr, [H|T])->
	Svr ! {self(), {get_file, H}},
	receive {_, {ok, _}}->
		io:format("File:~p: ~n", [H])
		%,io:format("~p", [Content])
	end,
	goTest1(Svr, T);

goTest1(_, [])->
	ok.
