#!/bin/bash

export PS1="\n\u \l [exit \$?] \t\n\w\[$(tput sgr0)\]$(parse_git_branch)\n$ "
