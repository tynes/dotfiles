#!/bin/bash

if [ `uname` == "Darwin" ]; then
	export PATH=$PATH:/usr/local/opt/go/libexec/bin
fi

mkdir -p $HOME/golang
export GOROOT=$HOME/golang
export PATH=$PATH:$GOROOT/bin
export GOPATH=~/golang


