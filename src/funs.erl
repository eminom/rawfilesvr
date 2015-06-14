

-module(funs).
-export([make_bin/3]).
-include("common.hrl").

-ifdef(ActiveGo).
make_bin(_Length, MsgID, Payload)->
	<<MsgID:32/big, Payload/binary>>.

-else.
make_bin(Length, MsgID, Payload)->
	<<Length:32/big, MsgID:32/big, Payload/binary>>.

-endif.
