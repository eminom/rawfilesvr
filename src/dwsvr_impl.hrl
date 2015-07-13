

%% The common body for directory and world server
%% imports the records.
-include("proto/cs_dir_pb.hrl").
-include("msgids.hrl").
-include("common.hrl").

-ifdef(ActiveGo).
-	define(ActiveOn, true).
-	define(PrePacketSize, 4).
-	define(WELCOME, "Active Mode").
-else.
-	define(ActiveOn, false).
-	define(PrePacketSize, 0).
-	define(WELCOME, "Non-active").
-endif.

%% The master entry is here>>
start(SupServer) ->
	io:format("~p~n", [?WELCOME]),
	case gen_tcp:listen(?SVR_PORT,
		[ binary,
		  {packet, ?PrePacketSize} ,
		  {reuseaddr, true } ,
		  {active, ?ActiveOn}
		]
	) of
	{ok, Listen} ->
		spawn(fun()->wait_and_serv(Listen, SupServer) end),
		noop_loop();
	{error, Reason} ->
		io:format("Error starting server:<~p>~n", [Reason]),
		ok
	end.

noop_loop()->
	receive
		after 30000 ->
			ok
	end,
	noop_loop().

wait_and_serv(Listen, SupServer)->
	case gen_tcp:accept(Listen) of 
		{ok, Sock} ->
			{ok, {Address, Port}} = inet:peername(Sock),
			ok = gen_server:cast(SupServer, {accept_once_more, {{Address, Port}, date(), time()}}),
			spawn(fun() -> wait_and_serv(Listen, SupServer) end),
			%io:format("New connection established ~n"),
			serv_loop(Sock)
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%PASSIVE MODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-ifndef(ActiveGo).

serv_loop(Socket)->
	case gen_tcp:recv(Socket, 4) of 
		{ok, <<Length:32/big>>} ->
			serv_loopbody(Socket, Length);
		{error, Reason}->
			ok   % Quit in silence.
	end.

serv_loopbody(Socket, L)->
	{ok, <<MsgID:32/big, Payload/binary>>} = gen_tcp:recv(Socket, L - 4 - ?LEN_FIX),
	serv_distribute(Socket, MsgID, Payload).

-else.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ACTIVE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

serv_loop(Socket)->
	receive
		{tcp, Socket, Bin} ->
			<<MsgID:32/big, Payload/binary>> = Bin,
			serv_distribute(Socket, MsgID, Payload);
		{tcp_closed, Socket}->
			void
	end.

-endif.

serv_distribute(Socket, ID, Payload)->
	case ID of
		?MsgID_RequestWorldList ->
			dir:handle_response_worldlist(Socket),
			serv_loop(Socket);
		?MsgID_RequestUserRegister ->
			dir:handle_response_userregister(Socket, Payload),
			serv_loop(Socket);
		?MsgID_RequestLogin ->
			world:handle_response_requestlogin(Socket, Payload),
			serv_loop(Socket);
		Else ->
			io:format("Cannot process MSGID<~p>~n",[Else]),
			exit(not_implemented_yet)
	end.


%The old one: complies only with ERLANG client.	
%serv_loop(Sock)->
%	receive
%		{tcp, Sock, Bin}->
%			%io:format("Try matching !~n"),
%			io:format("<~p>~n",[Bin]),
%			case Bin of 
%				<<MsgID:4/binary, _/binary>> ->
%					io:format("Msg-ID: ~w~n", [MsgID]),
%					gen_tcp:send(Sock, Bin),
%					serv_loop(Sock);
%				_ ->
%					gen_tcp:send(Sock, <<"Bye">>),
%					gen_tcp:close(Sock)
%			end;
%		{tcp_closed, Sock}->
%			io:format("connection closed~n")
%			%wait_and_serv(Listen)
%	end.
