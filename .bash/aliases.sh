#!/usr/bin/env bash

function src() {
    source ~/.bashrc
}

# make assumption of installed program based on OS
if [[ "$(uname -s)" == 'Linux' ]]; then
    # gnu ls
    alias ls='ls --color'
    alias open='xdg-open'
    alias pbcopy='xclip -selection clipboard'
else
    # bsd ls
    alias ls='ls -G'
fi

alias psg='ps -ef | grep -i $1'
alias nsg='netstat -natp | grep -i $1'

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

alias diff='difft'

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
