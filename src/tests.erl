

-module(tests).
-include_lib("eunit/include/eunit.hrl").
-include("proto/cs_dir_pb.hrl").

%% This is pure test.
record_test()->
	iolist_to_binary(
		cs_dir_pb:encode_responseworldlist(#responseworldlist{ 
			world_list = [ 
				#data_worldinfo{
					host = "192.168.1.106",
					port = 12000,  
					id   = 1008,
					name = "Erlang World Server"
				}
			]
		})
	),
	ok.
