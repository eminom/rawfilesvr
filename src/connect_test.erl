
-module(connect_test).
-export([start/0]).

start()->
	{ok, Sock} = gen_tcp:connect("localhost",
		11000,
		[binary, {packet,4}]
	),
	ok = gen_tcp:send(Sock, <<1,3,2,4,"ABC">>),
	receive
		{tcp, Sock, Bin}->
			io:format("<~p>~n", [Bin]),
			gen_tcp:close(Sock)
	end.
