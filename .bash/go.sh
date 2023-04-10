#!/bin/bash

if command -v go &> /dev/null
then
    export GO111MODULE=on
    export GOROOT=$(go env GOROOT)
    export GOPATH=$HOME/go
    PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
fi
