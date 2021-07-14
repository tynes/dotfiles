#!/bin/bash

export GO111MODULE=on
export PATH=$PATH:$HOME/go/bin

if [ -d $HOME/go ]; then
    export PATH=$PATH:$HOME/go/bin
fi
