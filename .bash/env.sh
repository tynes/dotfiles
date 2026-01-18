#!/bin/bash

export PAGER=nvimpager

# less options
export LESS='-R -C -M -I -j 10 -# 4'
# -C - make full screen reprints faster
# -M - display more info in status line
# -I - ignore casing in search
# -j 10 - display search results in line 10
# -# 4 - move 4 characters left/right on arrow key press

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

# homebrew - add to PATH first so brew command works
if [ -d /opt/homebrew/bin ]; then
    PATH="/opt/homebrew/bin:$PATH"
fi

# git completion
if command -v brew &> /dev/null; then
    source $(brew --prefix)/etc/bash_completion.d/git-completion.bash 2>/dev/null
fi

# import foundry tooling
if [ -d "$HOME/.foundry/bin" ]; then
    PATH="$PATH:$HOME/.foundry/bin"
fi

# cargo rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

if command -v nvim &> /dev/null
then
    export EDITOR=nvim
fi

if [ -d /usr/local/bin ]; then
    PATH="$PATH:/usr/local/bin"
fi

if [ -d /usr/local/go/bin ]; then
    PATH="$PATH:/usr/local/go/bin"
fi

# this is the bin at the root of the repo
if [ -d "$HOME/bin" ]; then
    PATH="$PATH:$HOME/bin"
fi

if [ -d "$HOME/.local/bin" ]; then
    PATH="$PATH:$HOME/.local/bin"
fi

# Bitwarden SSH agent
function bw_ssh_agent() {
    if [ -S "$HOME/.bitwarden-ssh-agent.sock" ]; then
        export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
    fi
}

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.bash 2>/dev/null || :
