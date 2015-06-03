
%% %%%%%%%%
%% This is the rawfilesvr roots
%% 

-module(filesvr).
-export([start/0, test/0]).

-define(TEST_HOST, "localhost").
-define(PORT, 4300).
-define(PACKPRESIZE, 0).
-define(TEST_FILE, "afilesvr.erl").

start()->
	start_svr().
	
start_svr()->
	{ok, Listen} = gen_tcp:listen(
		 ?PORT,
	   [binary, 
		  {packet, ?PACKPRESIZE},
		 	{reuseaddr, true},
			{active, true}
		]),
	spawn(fun()->par_connect(Listen) end).

%% Parallel accepts.>>
par_connect(Listen)->
  {ok, Socket} = gen_tcp:accept(Listen),
	spawn(fun()->par_connect(Listen) end),
	serve_loop(Socket).

serve_loop(Socket)->
	{ok, Content} = file:read_file(?TEST_FILE),
	gen_tcp:send(Socket, Content),
	gen_tcp:close(Socket).

test()->
	start(),
	{ok, Socket} = gen_tcp:connect(
		?TEST_HOST, 
		?PORT,
		[binary,
			{packet, ?PACKPRESIZE}
		]),
	receive
		{tcp, Socket, Bin}->
			io:format("~p", [Bin]),
			gen_tcp:close(Socket)
	end.
	
	


	


