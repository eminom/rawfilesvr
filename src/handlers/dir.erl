

-module(dir).
-export([handle_response_worldlist/1,
	handle_response_userregister/2]).

-include("proto/cs_dir_pb.hrl").
-include("msgids.hrl").
-include("common.hrl").

%% This file shall be read from configuration file.>>
-define(World_HOST, "192.168.1.105").
-define(World_PORT, 12000).
-define(World_SvrID, 1008).
-define(World_NAME,  "Erlang World Server").


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
	FullBin = funs:make_bin(Length, ?MsgID_ResponseWorldList, ResBin),
	ok = gen_tcp:send(Sock, FullBin).

handle_response_userregister(Sock, Payload)->
	Register = cs_dir_pb:decode_requestuserregister(Payload),
	#requestuserregister{account=Account, password=Password} = Register,
	io:format("Register User for <~p>:<~p>~n",[Account, Password]),
	ResBin = iolist_to_binary(
		cs_dir_pb:encode_responseuserregister(#responseuserregister{})
	),
	Length = byte_size(ResBin) + 8 + ?LEN_FIX,
	gen_tcp:send(Sock, funs:make_bin(Length, ?MsgID_ResponseUserRegister, ResBin)).
