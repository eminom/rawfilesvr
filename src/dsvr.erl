
%%% Is it a good TV series ??
%%% Sherlock Holmes ??

-module(dsvr).
-export([start/0, record_test/0]).

-define(PORT, 11000).
-define(LENGTH_WIDTH, 4).

%% imports the records.
-include("proto/cs_dir_pb.hrl").

record_test()->
	Response = #responseworldlist{ 
				world_list = [ 
					#data_worldinfo{
						host = "192.168.1.106",
						port = 12000,  
						id   = 1008,
						name = "Erlang World Server"
					}
				]
			},
	_ = iolist_to_binary(
		cs_dir_pb:encode_responseworldlist(Response)
	),
	ok.


start()->
	{ok, Listen} = gen_tcp:listen(?PORT,
		[ binary,
			{packet, 0},
			{reuseaddr, true},
			{active, false}
		]
	),
	spawn(fun()->wait_and_serv(Listen) end),
	noop_loop().

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
serv_loop(Sock)->
	case gen_tcp:recv(Sock, ?LENGTH_WIDTH) of 
		{ok, Bin}->
			<<L:32/big>> = Bin,
			serv_loop_body(Sock, L - ?LENGTH_WIDTH);
		{error, Reason}->
			io:format("ERROR CLIENT:<~p>~n", [Reason]),
			ok  %The end of this process
	end.

serv_loop_body(Sock, Len)->
	case gen_tcp:recv(Sock, Len) of
		{ok, Bin}->
			<<MsgID:32/little, Payload/binary>> = Bin,
			io:format("MsgID:<~p>~n", [MsgID]),
			serv_distribute(Sock, MsgID, Payload);
		{error, Reason}->
			io:format("ERROR:<~p>~n", [Reason]),
			ok
	end.

serv_distribute(Socket, ID, Payload)->
	case ID of
		1001 ->
			Response = #responseworldlist{ 
				world_list = [ 
					#data_worldinfo{
						host = "192.168.1.106",
						port = 12000,  
						id   = 1008,
						name = "Erlang World Server"
					}
				]
			},
			ResBin = iolist_to_binary(
				cs_dir_pb:encode_responseworldlist(Response)
			),
			Length = byte_size(ResBin) + 8,
			FullBin = <<Length:32/big,(ID+100000):32/little,
				ResBin/binary>>,
			%io:format("Response:~p~n", [FullBin]),
			gen_tcp:send(Socket, FullBin),
			serv_loop(Socket);
		Else ->
			io:format("Cannot process MSGID<~p>~n",[Else]),
			exit(notImplementYet)
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

