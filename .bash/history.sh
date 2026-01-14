#!/usr/bin/env bash

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