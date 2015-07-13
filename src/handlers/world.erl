
-module(world).
-export([handle_response_requestlogin/2]).
-include("../proto/cs_world_pb.hrl").
-include("../msgids.hrl").
-include("../common.hrl").

handle_response_requestlogin(Socket, Payload)->
	#requestlogin{
		is_anonymous = IsAnonymous,
		device_id = DeviceID,
		account = Account,
		password = Password
		} = cs_world_pb:decode_requestlogin(Payload),
	io:format("RequestLogin <~p>:<~p>:<~p>:<~p>~n",[IsAnonymous, DeviceID, Account, Password]),
	ResBin = iolist_to_binary(
		cs_world_pb:encode_responselogin(#responselogin{
			token="toekn"
			}
		)
	),
	Length = byte_size(ResBin) + 8 + ?LEN_FIX,
	ok = gen_tcp:send(Socket, funs:make_bin(Length, ?MsgID_ResponseLogin, ResBin)).
