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

# useful for renaming strings in a file
# usage $ rdir file target_string replacement_string
function rdir() {
    find $1 -type f -exec sed -i '' "s#$2#$3#" {} \;
}

# load file into repl like python -i
function nodei() {
    node -i -e "$(< $1 )"
}

# neovim
alias e='nvim'

alias pwdcp='pwd | pbcopy'

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

# TODO: do some pretty printing
function dexec() {
    local selected_image
    selected_image=$(docker ps --format='NAME: {{.Names}}, ID: {{.ID}}, IMAGE: {{.Image}}, COMMAND: {{.Command}}, PORTS: {{.Ports}}' | fzf)
    local id
    id=$(echo "$selected_image" | cut -f2 -d ',' | cut -f2 -d ':' | tr -d ' ')
    local cmd
    local dcmd=${1:-/bin/bash}
    cmd="docker exec -it ${id} ${dcmd}"
    echo "running: ${cmd}"
    eval "$cmd"
}

# TODO: doesn't work with passing along other docker opts
function dif() {
    [[ "$#" -ne 1 ]] && printf "usage:\n$ dif <regex>\n" && return 1;
    local cmd
    cmd="--filter=reference=$1"
    echo "docker images $cmd"
    docker images $cmd
}

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

# openssl
alias cert='openssl x509 -noout -text -in'
alias req='openssl req -noout -text -in'
alias crl='openssl crl -noout -text -in'
alias ssl='openssl s_client -connect'

function valid_key_pair() {
    # TODO: if not 2 args, print usage
    local key_hash
    local cert_hash
    key_hash=$(openssl rsa -noout -modulus -in "${1}" | openssl md5)
    cert_hash=$(openssl x509 -noout -modulus -in "${2}" | openssl md5)
    echo "cert hash: $cert_hash"
    echo "key hash:  $key_hash"
    if [ "$cert_hash" == "$key_hash" ]; then
        echo "matching cert/key pair"
    else
        echo "not a pair"
    fi
}

# kubernetes stuff
alias k='kubectl'

# TODO: clean up, add empty response handling, no kubectl handling
function kube_pf() {
    if [[ ! -x "$(which fzf 2>/dev/null)" ]]; then
        echo "please install: github.com/junegunn/fzf" >&2
        return 1
    fi

    local selected_pod
    selected_pod=$( kubectl get po \
        | grep -v "NAME" | awk '{ print $1 }' \
        | sort | fzf --select-1 \
    )

    local selected_container
    selected_container=$( kubectl get po ${selected_pod} \
        -o=jsonpath='{..containers[*].name}' | uniq \
        | sort | tr ' ' '\n' | fzf --select-1 \
    )

    template="{{- range .spec.containers -}}{{- if eq .name \"${selected_container}\" -}}{{- range .ports -}} {{.containerPort }} {{ end -}}{{- end -}}{{- end -}}"

    local selected_port
    selected_port=$(kubectl get po ${selected_pod} \
        -o go-template --template="${template}" \
        | tr ' ' '\n' | fzf \
    )

    echo "Port forwarding ${selected_pod}/${selected_container} at port ${selected_port}"

    if [[ ! -z "$selected_port" ]]; then
        kubectl port-forward ${selected_pod} ${selected_port}
    fi
}

alias kube_pf='kube_pf'

function pdir() {
    local SPLIT='/'
    local COUNT
    COUNT=$(echo "${PWD}" \
        | awk -F"${SPLIT}" '{print NF-1}')
    local cmd
    local letter_count
    local half
    local pad
    local to_print=""
    for i in $(seq $COUNT); do
        extra=""
        cmd="echo $PWD | cut -f$(($i+1)) -d ""'$SPLIT'"
        result=$(eval $cmd)
        letter_count=${#result}
        half=$(($letter_count/2))
        if [ $(($letter_count%2)) -eq 0 ]; then
            half=$(($half-1))
        fi
        if [[ $(($half+$half+1)) -lt $letter_count ]]; then
            extra="-"
        fi
        # take into account the slash
        cmd="printf ""'%${half}s' | tr ' ' '-'"
        pad=$(eval $cmd)
        to_print=${to_print}/${pad}"$(($COUNT-$i))"${extra}${pad}
    done
    echo "$PWD"
    echo "$to_print"
}
