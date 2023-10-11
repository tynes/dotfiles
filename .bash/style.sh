#!/usr/bin/env bash

function ps1_git_hash_short() {
    git rev-parse --short HEAD 2>/dev/null | xargs printf "[%s]"
}

function ps1_parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

export PS1="\n\u \l [exit \$?] \t\n\w\[\$(tput sgr0)\]\$(ps1_parse_git_branch) \$(ps1_git_hash_short)\n$ "
