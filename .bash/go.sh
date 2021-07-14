#!/bin/bash

mkdir -p $HOME/golang
export GO111MODULE=on

if [ -d $HOME/go ]; then
    export PATH=$PATH:$HOME/go/bin
fi
