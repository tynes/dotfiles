#!/bin/bash


mkdir -p $HOME/golang

# check if homebrew installed, then set GOROOT appropriately
if [ `uname` == "Darwin" ] && [[ -x "$(command -v brew)" ]]; then
    export GOROOT=/usr/local/opt/go/libexec
else
    # TODO: setup for linux
    export GOROOT=
fi

export GOPATH=$HOME/golang
export PATH=$PATH:$GOPATH/bin
