

%% The common body for directory and world server
%% imports the records.
-include("proto/cs_dir_pb.hrl").
-include("msgids.hrl").
-include("common.hrl").

%% This file shall be read from configuration file.>>
-define(World_HOST, "192.168.1.106").
-define(World_PORT, 12000).
-define(World_SvrID, 1008).
-define(World_NAME,  "Erlang World Server").


%% The master entry is here>>
start()->
	case gen_tcp:listen(?SVR_PORT,
		[ binary,
		  {packet, 0 } ,
		  {reuseaddr, true } ,
		  {active, false }
		]
	) of
	{ok, Listen} ->
		spawn(fun()->wait_and_serv(Listen) end),
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

wait_and_serv(Listen)->
	case gen_tcp:accept(Listen) of 
		{ok, Sock} ->
			spawn(fun() -> wait_and_serv(Listen) end),
			%io:format("New connection established ~n"),
			serv_loop(Sock)
	end.

%New one>>
%
%serv_loop(Sock)->
%	receive 
%		{tcp, Sock, Bin} ->
%			<<MsgID:32/big, Payload/binary>> = Bin,
%			serv_distribute(Sock, MsgID, Payload);
%		{tcp_closed, Sock} ->
%			io:format("Disconnected~n"),
%			ok
%	end.
%% {ok, Bin} or {error, Reason}

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

serv_distribute(Socket, ID, Payload)->
	case ID of
		?MsgID_RequestWorldList ->
			handle_response_worldlist(Socket),
			serv_loop(Socket);
		?MsgID_RequestUserRegister ->
			handle_response_userregister(Socket, Payload),
			serv_loop(Socket);
		?MsgID_RequestLogin ->
			world:handle_response_requestlogin(Socket, Payload),
			serv_loop(Socket);
		Else ->
			io:format("Cannot process MSGID<~p>~n",[Else]),
			exit(not_implemented_yet)
	end.

%% The handlers for 
handle_response_worldlist(Sock)->
	Response = #responseworldlist{ 
		world_list = [ 
			#data_worldinfo{
				host = ?World_HOST,
				port = ?World_PORT,
				id   = ?World_SvrID,
				name = ?World_NAME
			}
		]
	},
	ResBin = iolist_to_binary(
		cs_dir_pb:encode_responseworldlist(Response)
	),
	Length = byte_size(ResBin) + 8 + ?LEN_FIX,
	FullBin = <<Length:32/big, 
		(?MsgID_ResponseWorldList):32/big, ResBin/binary>>,
	%io:format("Response:~p~n", [FullBin]),
	gen_tcp:send(Sock, FullBin).

handle_response_userregister(Sock, Payload)->
	Register = cs_dir_pb:decode_requestuserregister(Payload),
	#requestuserregister{account=Account, password=Password} = Register,
	io:format("Register User for <~p>:<~p>~n",[Account, Password]),
	ResBin = iolist_to_binary(
		cs_dir_pb:encode_responseuserregister(#responseuserregister{})
	),
	Length = byte_size(ResBin) + 8 + ?LEN_FIX,
	gen_tcp:send(Sock, <<Length:32/big, (?MsgID_ResponseUserRegister):32/big, ResBin/binary>>).

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