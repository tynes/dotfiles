#!/bin/bash

# ROOT_DIR is home directory when ~/dotfiles
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR=$(dirname $DIR)

# import foundry tooling
if [ -d "$HOME/.foundry/bin" ]; then
    path_add "$HOME/.foundry/bin"
fi

if [ -d /opt/homebrew/bin ]; then
    path_add /opt/homebrew/bin before
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

# ruby executables
if [ -d "$HOME/.gem/ruby/2.7.0" ]; then
    path_add "$HOME/.gem/ruby/2.7.0/bin"
fi

if [ -d "/opt/homebrew/sbin" ]; then
    path_add "/opt/homebrew/sbin"
fi

if [ -d "$HOME/.local/bin" ]; then
    path_add "$HOME/.local/bin"
fi

# hardware gpg signing on linux for local user
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

# source bash completions
if [ -d /usr/local/etc/bash_completion.d ]; then
    for filename in /usr/local/etc/bash_completion.d/*; do
        [ -e "$filename" ] || continue
        source "$filename"
    done
fi

if [ -f /usr/share/fzf/key-bindings.bash ]; then
    source /usr/share/fzf/key-bindings.bash
fi

if [ -f $(which direnv) ]; then
    eval "$(direnv hook bash)"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Setup fzf
# ---------
if [[ ! "$PATH" == *$HOME/.fzf/bin* ]]; then
  path_add $HOME/.fzf/bin
fi

# Auto-completion
# ---------------
[[ $- == *i* && -f "$HOME/.fzf/shell/completion.bash" ]] && source "$HOME/.fzf/shell/completion.bash" 2> /dev/null

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# Bitwarden SSH agent
if [ -S "$HOME/.bitwarden-ssh-agent.sock" ]; then
    export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
fi

if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
fi

# This should run at the end of modifying the PATH
path_clean
