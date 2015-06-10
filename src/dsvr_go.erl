
-module(dsvr_go).
-export([start/0]).

-define(PORT, 11000).
-define(HOST, "localhost").

start()->
	{ok, Sock} = gen_tcp:connect(?HOST,
		?PORT,
		[binary, {packet,4}]
	),
	%ok = gen_tcp:send(Sock, term_to_binary(<<1,3,2,4,"ABC">>)),
	ok = gen_tcp:send(Sock, <<1,3,2,4,"ABC">>),
	receive
		{tcp, Sock, Bin}->
			io:format("<~p>~n", [Bin]),
			gen_tcp:close(Sock)
	end.
