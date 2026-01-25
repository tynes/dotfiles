#!/usr/bin/env bash

# =============================================================================
# Locale
# =============================================================================

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# =============================================================================
# History
# =============================================================================

alias hist='history'

# Don't save commands prefixed with a space, and remove all duplicate entries.
# `ignoreboth` is a shortcut for `ignorespace:ignoredups`.
export HISTCONTROL=ignoreboth:erasedups

# Ignore common, trivial commands.
export HISTIGNORE="ls:cd:bg:fg:history:exit"

# Add timestamps to history, e.g., "2026-01-14 15:30:00".
export HISTTIMEFORMAT="%F %T "

# Append to the history file instead of overwriting it when the shell exits.
shopt -s histappend

# Use a large history file size.
export HISTSIZE=100000
export HISTFILESIZE=100000

# After each command, append to the history file and reread it to share
# history between running terminals.
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'
'}history -a; history -c; history -r"

# =============================================================================
# Aliases
# =============================================================================

function src() {
    source ~/.bashrc
}

function psg() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: psg <pattern>" >&2
        return 1
    fi
    ps -ef | grep -i "$1"
}

function nsg() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: nsg <pattern>" >&2
        return 1
    fi
    netstat -natp | grep -i "$1"
}

alias ls='eza'
alias la='ls -a'
alias ll='ls -l'
alias lla='ls -la'
alias l='ls'
alias ..='cd ..'
alias c='clear'
function mkcd() { mkdir -p "$@" && cd "$_"; }
function cdls() { cd "$@" && ls; }
alias z='zoxide'
# neovim
alias e='nvim'
# shorter cat
alias ca='BAT_PAGER=never bat'
# shorter less
alias les='moor'
# shorter diff
alias dif='difft'

# git
alias g='git'
alias gs='git status'
alias gp='git pull'
alias gd='git diff'
alias gpom='git pull origin master'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gl="git log --graph --pretty=format:'%Cred%h%Creset \
-%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# docker
alias d='docker'
alias di='docker images'
alias dps='docker ps'
alias dc='docker-compose'
alias dclean="docker images -f 'dangling=true' | xargs docker rmi"
alias dcleans="docker ps -a --format='{{.ID}}' | xargs docker rm"

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;

# kubernetes stuff
alias k='kubectl'

# =============================================================================
# Completions
# =============================================================================

# GitHub CLI autocompletion
if command -v gh &> /dev/null; then
  eval "$(gh completion -s bash)"
fi

# Jujutsu (jj) CLI autocompletion
if command -v jj &> /dev/null; then
  eval "$(jj util completion bash)"
fi

# =============================================================================
# Style / Prompt
# =============================================================================

function ps1_git_hash_short() {
    git rev-parse --short HEAD 2>/dev/null | xargs printf "[%s]"
}

function ps1_parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

if [[ "$(uname)" == 'Darwin' ]]; then
    update_terminal_cwd() {
        # Identify the directory using a "file:" scheme URL,
        # including the host name to disambiguate local vs.
        # remote connections. Percent-escape spaces.
        local SEARCH=' '
        local REPLACE='%20'
        local PWD_URL="file://$HOSTNAME${PWD//$SEARCH/$REPLACE}"
        printf '\e]7;%s\a' "$PWD_URL"
    }
fi

export PS1="\n\u \l [exit \$?] \t\n\w\[\$(tput sgr0)\]\$(ps1_parse_git_branch) \$(ps1_git_hash_short)\n$ "

# Initialize starship prompt if available
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# =============================================================================
# Environment / Integrations
# =============================================================================

# direnv
if [ -f $(which direnv) ]; then
    eval "$(direnv hook bash)"
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

# =============================================================================
# zoxide (must be last)
# =============================================================================

if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
fi
