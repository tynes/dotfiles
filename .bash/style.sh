#!/usr/bin/env bash

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
