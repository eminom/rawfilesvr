all:
	rebar compile
	cp src/proto/*.beam ebin

clean:
	rebar clean
