
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
	get_accept_count/0]
	).

-define(SERVER, ?MODULE).
-define(PORT, 1055).

-define(DirServer,  {dsvr, start}).
-define(WorldServer,{wsvr, start}).

-record(server_state, {
	port = 0,
	lsock = null,
	accept_count = 0,
	loop    
}).

get_accept_count()->
	{ok, Count} = gen_server:call(?SERVER, accepted_count),
	Count.

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
	{reply, {ok, State#server_state.accept_count}, State}.

handle_cast(accept_once_more, State)->
	{noreply, State#server_state{accept_count = State#server_state.accept_count + 1 }};
	
handle_cast(_Request, State)->
	{noreplay, State}.

handle_info(_Info, State)->
	{noreply, State}.







