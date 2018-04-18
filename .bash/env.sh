#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR=`dirname $DIR`

# TODO - does this override native things?
export VIM_RUNTIME="$ROOT_DIR/vim_runtime"

# maybe a mac only thing?
export PATH="$PATH:/usr/local/sbin"
