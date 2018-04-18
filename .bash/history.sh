alias hist='history'
# Avoid duplicates
export HISTCONTROL=ignoredups:erasedups

# append to the history file instead of overwriting
# it when shell exits
shopt -s histappend
# large history file size
export HISTSIZE=100000
export HISTFILESIZE=100000

# After each command, append to the history file and reread it
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"
