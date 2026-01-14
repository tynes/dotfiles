#!/bin/bash

# ROOT_DIR is home directory when ~/dotfiles
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR=$(dirname $DIR)

# direnv
if [ -f $(which direnv) ]; then
    eval "$(direnv hook bash)"
fi

# zoxide
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
fi

# fzf
if command -v fzf &> /dev/null; then
    eval "$(fzf --bash)"
fi

# ssh
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
fi

# homebrew
if command -v brew &> /dev/null; then
    path_add $(brew --prefix)/bin before
fi

# import foundry tooling
if [ -d "$HOME/.foundry/bin" ]; then
    path_add "$HOME/.foundry/bin"
fi

# cargo rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

if command -v nvim &> /dev/null
then
    export EDITOR=nvim
fi

if [ -d /usr/local/bin ]; then
    path_add /usr/local/bin
fi

if [ -d /usr/local/go/bin ]; then
    path_add /usr/local/go/bin
fi

if [ -d "$HOME/bin" ]; then
    path_add "$HOME/bin"
fi

if [ -d "$HOME/.local/bin" ]; then
    path_add "$HOME/.local/bin"
fi

# less options
export LESS='-R -C -M -I -j 10 -# 4'
# -C - make full screen reprints faster
# -M - display more info in status line
# -I - ignore casing in search
# -j 10 - display search results in line 10
# -# 4 - move 4 characters left/right on arrow key press

# Bitwarden SSH agent
function bw_ssh_agent() {
    if [ -S "$HOME/.bitwarden-ssh-agent.sock" ]; then
        export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
    fi
}

# This should run at the end of modifying the PATH
path_clean
