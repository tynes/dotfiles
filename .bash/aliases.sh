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
alias z='zoxide'

# neovim
alias e='nvim'

# move back up one directory and ls
function ..l() {
    cd .. && ls "$@"
}

function u() {
    [  "$#" -ne 1 ] && echo "usage: u [int] - traverse directories upwards"
    if [[ "$1" -gt 0 ]]; then
        for i in $(seq "$@"); do
            cd ..
        done
    fi
}

# mkdir and cd
function mkcd() { mkdir -p "$@" && cd "$_"; }

# cd and ls
function cdls() {
    cd "$@" && ls
}

# TODO: put this behind darwin flag
# use homebrew git
if which brew &>/dev/null; then
    alias git="`brew --prefix`/bin/git"
fi

# docker stuff
alias d='docker'
alias di='docker images'
alias dps='docker ps'
alias dc='docker-compose'
alias dclean="docker images -f 'dangling=true' | xargs docker rmi"
alias dcleans="docker ps -a --format='{{.ID}}' | xargs docker rm"

# git stuff
alias g='git'
alias gs='git status'
alias gp='git pull'
alias gd='git diff'
alias gpom='git pull origin master'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'

alias prettypath='tr ":" "\n" <<< "$PATH"'

# Enable tab completion for `g` by marking it as an alias for `git`
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if type _git &> /dev/null && [ -f `dirname $DIR`/git-completion.bash ]; then
  complete -o default -o nospace -F _git g;
fi;

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;

alias gl="git log --graph --pretty=format:'%Cred%h%Creset \
-%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# kubernetes stuff
alias k='kubectl'