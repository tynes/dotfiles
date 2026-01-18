#!/bin/bash

# Interactive shell hooks and integrations
# This file contains tools that enhance the interactive shell experience

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

# git completion
if command -v brew &> /dev/null; then
    source $(brew --prefix)/etc/bash_completion.d/git-completion.bash
fi

# Bitwarden SSH agent
function bw_ssh_agent() {
    if [ -S "$HOME/.bitwarden-ssh-agent.sock" ]; then
        export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
    fi
}

# Rust/Cargo
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.bash 2>/dev/null || :
