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

# bcoin stuff
function bcoin_help() {
    # to remember which env vars to use
	echo "BCOIN_URI"
	echo "BCOIN_API_KEY"
}
alias bcoin_help='bcoin_help'

# kubernetes stuff
# 😞 one day we will be reunited

