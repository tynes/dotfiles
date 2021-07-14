#!/bin/bash

# ROOT_DIR is home directory when ~/dotfiles
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR=$(dirname $DIR)

# TODO - side effects?
export VIM_RUNTIME="$ROOT_DIR/vim_runtime"


if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then
    . $HOME/.nix-profile/etc/profile.d/nix.sh
fi # added by Nix installer

# documented default go install path
export PATH="$PATH:/usr/local/bin/go"

# rust executables
if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$PATH:$HOME/.cargo/bin"
fi

# ruby executables
if [ -d "$HOME/.gem/ruby/2.7.0" ]; then
    export PATH="$PATH:$HOME/.gem/ruby/2.7.0/bin"
fi

# hardware gpg signing on mac for local user
if [ -d "$HOME/Library/Python/3.6/bin" ]; then
    export PATH="$PATH:$HOME/Library/Python/3.6/bin"
fi

# hardware gpg signing on linux for local user
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

# TODO: don't default to ledger
# currently default to using ledger
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
