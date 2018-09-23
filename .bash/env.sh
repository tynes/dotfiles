#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR=$(dirname $DIR)

# TODO - does this override native things?
export VIM_RUNTIME="$ROOT_DIR/vim_runtime"

# maybe a mac only thing?
export PATH="$PATH:/usr/local/sbin"

# ledger pgp signing on mac
if [ -d "$HOME/Library/Python/3.6/bin" ]; then
    export PATH="$PATH:$HOME/Library/Python/3.6/bin"
fi

# ledger pgp signing on linux
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

# TODO: don't default to ledger
# default to using ledger
# test commit
export GNUPGHOME=~/.gnupg/ledger

function gpghome() {
    selection=$(echo "$HOME/.gnupg/ledger
$HOME/.gnupg
$HOME/.gnupg/trezor" | fzf)
    export GNUPGHOME="$selection"
}

# less options
export LESS='-R -C -M -I -j 10 -# 4'
# -C - make full screen reprints faster
# -M - display more info in status line
# -I - ignore casing in search
# -j 10 - display search results in line 10
# -# 4 - move 4 characters left/right on arrow key press

# source bash completions
if [ -d /usr/local/etc/bash_completion.d ]; then
    for filename in /usr/local/etc/bash_completion.d/*; do
        [ -e "$filename" ] || continue
        source "$filename"
    done
fi
