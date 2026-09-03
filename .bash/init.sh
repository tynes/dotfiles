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
export -n PROMPT_COMMAND 2>/dev/null
__history_sync() { history -a; history -c; history -r; }
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}__history_sync"

# =============================================================================
# Aliases
# =============================================================================

function src() {
    source "$HOME/.profile"
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
export MOOR='--wrap --statusbar=bold'
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

# SSH host completion.
#
# Host names come from two places:
#   - Host entries in ~/.ssh/config and anything it Includes (config.d/*.conf)
#   - Tailscale peers, by their MagicDNS name
#
# known_hosts is deliberately not a source: config/ssh/config sets
# HashKnownHosts yes, so every name in it is a one-way hash.
#
# This is a function rather than `complete -W "$(...)"` because the latter runs
# at shell startup -- every new tmux pane would pay for it, and a host added
# afterwards wouldn't complete until the next login. A function builds the list
# on TAB instead.

_ssh_hosts_from_config() {
    local main="$HOME/.ssh/config"
    [ -r "$main" ] || return 0

    local files pattern expanded
    files=("$main")

    # Follow one level of Include. Patterns may be globs, may start with ~, and
    # are otherwise relative to ~/.ssh.
    while read -r _ pattern; do
        case "$pattern" in
            "~/"*) pattern="$HOME/${pattern#\~/}" ;;
            /*)    ;;
            *)     pattern="$HOME/.ssh/$pattern" ;;
        esac
        for expanded in $pattern; do
            [ -r "$expanded" ] && files+=("$expanded")
        done
    done < <(grep -iE '^[[:space:]]*Include[[:space:]]+' "$main" 2>/dev/null)

    # Drop patterns (*, ?) and negations (!): they aren't connectable names.
    awk 'tolower($1) == "host" { for (i = 2; i <= NF; i++) print $i }' \
        "${files[@]}" 2>/dev/null | grep -vE '[*?!]'
}

_ssh_hosts_from_tailscale() {
    command -v tailscale &> /dev/null || return 0

    # DNSName is authoritative; HostName can be junk (phones often report
    # "localhost"). Strip the trailing dot and the MagicDNS suffix -- the
    # tailnet is in the DNS search domain, so short names resolve on their own.
    if command -v jq &> /dev/null; then
        tailscale status --json 2>/dev/null \
            | jq -r '(.Self, .Peer[]?) | .DNSName // empty' \
            | sed 's/\.$//; s/\..*//'
    else
        tailscale status 2>/dev/null | awk '$1 ~ /^100\./ && NF > 1 { print $2 }'
    fi
}

_ssh_host_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}" prefix=""

    # Keep a user@ prefix intact while completing only the host part.
    case "$cur" in
        *@*) prefix="${cur%@*}@"; cur="${cur#*@}" ;;
    esac

    COMPREPLY=($(compgen -P "$prefix" -W \
        "$({ _ssh_hosts_from_config; _ssh_hosts_from_tailscale; } | sort -u)" \
        -- "$cur"))
}

# -o default so scp and sftp still complete local paths when no host matches.
complete -o default -F _ssh_host_complete ssh scp sftp

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
elif [ -f /usr/share/bash-completion/completions/git ]; then
    source /usr/share/bash-completion/completions/git
fi
# enable git completions for the 'g' alias
__git_complete g __git_main 2>/dev/null

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

# worktrunk (wt)
if command -v wt &> /dev/null; then
    eval "$(wt config shell init bash)"
fi

# Grok CLI (installs to ~/.grok via https://x.ai/cli/install.sh)
if [ -d "$HOME/.grok/bin" ]; then
    export PATH="$HOME/.grok/bin:$PATH"
    [ -r "$HOME/.grok/completions/bash/grok.bash" ] && source "$HOME/.grok/completions/bash/grok.bash"
fi

# opencode (installs to ~/.opencode via https://opencode.ai/install)
if [ -d "$HOME/.opencode/bin" ]; then
    export PATH="$HOME/.opencode/bin:$PATH"
fi

# =============================================================================
# zoxide (must be last)
# =============================================================================

if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
fi
