#!/usr/bin/env bash

function random_string() {
    LC_CTYPE=C tr -dc '0-9a-z' </dev/urandom | head -c"$1"
}

function random_bytes() {
    hexdump -n "$1" -e '4/4 "%08x"' /dev/random
}
