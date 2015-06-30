
-module(sup_server).
-behavior(gen_server).

-export([init/1,
	handle_info/2,
	handle_call/3,
	handle_cast/2,
	terminate/2,
	code_change/3]).

-export([
	start_link/0,
	get_accept_count/0,
	get_client_history/0,
	print_log/0
	]
	).

-define(SERVER, ?MODULE).
-define(PORT, 1055).

-define(DirServer,  {dsvr, start}).
-define(WorldServer,{wsvr, start}).

-record(server_state, {
	port = 0,
	lsock = null,
	accept_count = 0,
	loop = [],
	client_history = []   %Which is a list
}).

get_accept_count()->
	{ok, Count} = gen_server:call(?SERVER, accepted_count),
	Count.

get_client_history()->
	{ok, ClientHistory} = gen_server:call(?SERVER, fetch_client_history),
	ClientHistory.

print_log()->
	print_log( get_client_history() ).

print_log([{{Address, Port}, {Y, M, Day}, {Hr, Mn, S}}|T])->
	{Adot,Bdot,Cdot,Ddot} = Address,
	io:format("<~p.~p.~p.~p:~p> logged on at ~p-~p-~p,  ~p:~p:~p~n", [Adot,Bdot,Cdot, Ddot , Port, Y, M, Day, Hr, Mn, S]),
	print_log(T);

print_log([])->
	ok.

start_link()->
	State = #server_state{port = ?PORT, loop=[?DirServer, ?WorldServer]},
	gen_server:start_link({local, ?SERVER}, ?MODULE, State, []).

init(State=#server_state{loop=Mfs}) ->
	go_start(Mfs, State).

go_start([{Mod, Fun}|T], State)->
	spawn(Mod, Fun, [self()]),
	go_start(T, State);

go_start([], State)->
	{ok, State}.

%%% Always holds it
code_change(_OldVsn, State, _Extra)->
	{ok, State}.

terminate(_Reason, _State)->
	ok.

handle_call(accepted_count, _From, State)->
	{reply, {ok, State#server_state.accept_count}, State};

handle_call(fetch_client_history, _From, State)->
	{reply, {ok, State#server_state.client_history}, State}.

handle_cast({accept_once_more,Log}, State=#server_state{accept_count=AcceptCount, client_history=ClientHistory})->
	{noreply, State#server_state{accept_count = 1+AcceptCount, client_history=[Log] ++ ClientHistory }};
	
handle_cast(_Request, State)->
	{noreplay, State}.

handle_info(_Info, State)->
	{noreply, State}.







