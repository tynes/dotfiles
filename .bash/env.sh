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

export TERMINAL=$(ps -h -o comm -p $PPID)

if command -v nvim &> /dev/null
then
    export EDITOR=nvim
    export VIM_RUNTIME="$ROOT_DIR/vim_runtime"
fi

if [ -d /usr/local/bin ]; then
    path_add /usr/local/bin
fi

if [ -d /usr/local/go/bin ]; then
    path_add /usr/local/go/bin
fi

# rust executables
if [ -d "$HOME/.cargo/bin" ]; then
    path_add "$HOME/.cargo/bin"
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

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# Bitwarden SSH agent
function bw_ssh_agent() {
    if [ -S "$HOME/.bitwarden-ssh-agent.sock" ]; then
        export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
    fi
}

# This should run at the end of modifying the PATH
path_clean
