

%% This is a demo test for client.
%% Blocking mode is very ok.

-module(client).
-export([start/0]).

-define(HOST, "192.168.1.107").
-define(PORT,  11000).

-include("../msgids.hrl").
-include("../proto/cs_dir_pb.hrl").
-include("../proto/cs_world_pb.hrl").

start()->
	io:format("exploring dir ...~n"),
	explore_dir().

explore_dir()->
	case gen_tcp:connect(?HOST, ?PORT,
		[binary, 
			{packet, 4}  % And this is very necessary.
			%There is no need for {active, true}. %I am active by default
		]
	)
		of
		{ok, Socket}->
			dir_test_registeruser(Socket),
			{ok, Host, Port, Name, Id} = dir_pull_worldlist(Socket),
			explore_world(Host, Port, Name, Id);
		{error, Reason}->
			io:format("Error:<~p>~n",[Reason]),
			ok
	end.


dir_test_registeruser(Socket)->
	Bin = iolist_to_binary(cs_dir_pb:encode_requestuserregister(
		#requestuserregister{
			account = "Eminem",
			password= "hello"
		})),
	gen_tcp:send(Socket, <<(?MsgID_RequestUserRegister):32/big, Bin/binary>>),
	receive
		{tcp, Socket, InBuff}->
			<<(?MsgID_ResponseUserRegister):32/big, Payload/binary>> = InBuff,
			#responseuserregister{
				exception = Exception
			} = cs_dir_pb:decode_responseuserregister(Payload),
			io:format("RegisterUser: <~p>~n", [Exception])
	end.


%% And choose the first one.
dir_pull_worldlist(Socket)->
	Bin = iolist_to_binary(cs_dir_pb:encode_requestworldlist(#requestworldlist{})),
	gen_tcp:send(Socket, <<(?MsgID_RequestWorldList):32/big, Bin/binary>>),
	%io:format("Site ~p~n", [Socket]),
	%io:format("~p~n", [Bin]),   % And the Bin continues.
	receive
		{tcp, Socket, InBuff} ->
			<<(?MsgID_ResponseWorldList):32/big, Payload/binary>> = InBuff,
			#responseworldlist{
				world_list = WorldList
			} = cs_dir_pb:decode_responseworldlist(Payload),
			print_world_list(WorldList),
			gen_tcp:close(Socket),
			case WorldList of
				[#data_worldinfo{
					host = Host,
					port = Port,
					name = Name,
					id   = Id
				}|_] ->
					{ok, Host, Port, Name, Id};
				[] ->
					io:format("Empty world list~n"),
					void
			end;
		{tcp_closed, Socket}->
			io:format("error connection~n"),
			exit(error)
	end.

print_world_list([#data_worldinfo{
	host = Host,
	port = Port,
	id   = SvrID,
	name = Name
	}|T])->
	io:format("<Host:~p> <~p>:<~p>  id=~p~n",[Name, Host, Port, SvrID]),
	print_world_list(T);

print_world_list([])->
	ok.

explore_world(_Host, _Port, Name, Id)->
	io:format("exploring world <~p:~p>~n", [Name,Id]),
	ok.
