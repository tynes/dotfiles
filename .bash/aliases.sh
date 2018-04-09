#!/bin/bash

# TODO: test portability across operating systems

# directory traversing
alias ls='ls -G'
alias la='ls -a'
alias ll='ls -l'
alias lla='ls -la'
alias l='ls'
alias ..='cd ..'
alias c='clear'

# move back up one directory and ls
function ..l() {
    cd .. && ls "$@"
}

function u() {
    # TODO - check if int
    if [[ "$#" -eq 1 ]]; then
        for i in `seq "$@"`; do
            cd ..
        done
    else
        echo "usage: u [int]"
        echo "traverse [int] directories upwards"
    fi
}

# file search
function f() {
    find . -iname "*$1*" ${@:=2}
}
function r() {
    grep "$1" ${@:=2} -R .
}
# mkdir and cd
function mkcd() { mkdir -p "$@" && cd "$_"; }
# cd and ls
function cdls() {
    cd "$@" && ls
}

# on a mac machine
if [ `uname` == "Darwin" ]; then
	# TODO: get newest version instead of hardcoding
	GIT_VERSION=2.17.0
	# the path when it has been installed via homebrew
    # TODO: can use `brew --prefix`
	GIT_PATH="/usr/local/Cellar/git/$VERSION/bin/git"
	if [ -f $GIT_PATH ]; then
		alias git="$GIT_PATH"
	fi
fi

# docker stuff
alias d='docker'
alias di='docker images'
alias dps='docker ps'
alias dc='docker-compose'
alias dclean="docker images -f 'dangling=true' | xargs docker rmi"
alias dcleans="docker ps -a --format='{{.ID}}' | xargs docker rm"

# clean up docker environment
function dcleanf() {
    docker rm -v $(docker ps --filter 'status=exited' -q 2>/dev/null) 2>/dev/null
    docker rmi $(docker images --filter 'dangling=true' -q 2>/dev/null) 2>/dev/null
}
alias dcleanf='dcleanf'

# git stuff
alias g='git'
alias gs='git status'
alias gp='git pull'
alias gd='git diff'
alias gpom='git pull origin master'
alias ga='git add'
alias gc='git commit'

parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# Enable tab completion for `g` by marking it as an alias for `git`
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if type _git &> /dev/null && [ -f `dirname $DIR`/git-completion.bash ]; then
  complete -o default -o nospace -F _git g;
fi;

# share current directory on port 8000
alias webshare='python -m SimpleHTTPServer'

alias gl="git log --graph --pretty=format:'%Cred%h%Creset \
-%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# bcoin stuff
function bcoin_help() {
    # to remember which env vars to use
	echo "BCOIN_URI"
	echo "BCOIN_API_KEY"
}
alias bcoin_help='bcoin_help'

# kubernetes stuff
# 😞 one day we will be reunited

