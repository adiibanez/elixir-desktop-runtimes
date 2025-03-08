#!/bin/bash

# ensure there is rebar3 in path
export PATH=$PATH:~/.mix
export ERL_INCLUDE_PATH=`erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell`

# mix has priority over `make` for projects like exqlite
if [ -f "mix.exs" ]; then
    exec mix do deps.get, release --overwrite
fi

if [ -f "Makefile" ]; then
    exec make
fi

if [ -f "rebar.config" ]; then
    ERL_FLAGS="-ssl verify verify_none" exec ~/.mix/rebar3 compile
fi

echo "Could not identify how to build this nif"
exit 1