#!/bin/bash

# ROOT_DIR is home directory when ~/dotfiles
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR=$(dirname $DIR)

# import foundry tooling
if [ -d "$HOME/.foundry/bin" ]; then
    PATH="$PATH:$HOME/.foundry/bin"
fi

export TERMINAL=$(ps -h -o comm -p $PPID)

if command -v nvim &> /dev/null
then
    export EDITOR=nvim
    export VIM_RUNTIME="$ROOT_DIR/vim_runtime"
fi

if [ -d /usr/local/go/bin ]; then
    export PATH=$PATH:/usr/local/go/bin
fi

# rust executables
if [ -d "$HOME/.cargo/bin" ]; then
    PATH="$HOME/.cargo/bin:$PATH"
fi

# ruby executables
if [ -d "$HOME/.gem/ruby/2.7.0" ]; then
    PATH="$PATH:$HOME/.gem/ruby/2.7.0/bin"
fi

# hardware gpg signing on linux for local user
if [ -d "$HOME/.local/bin" ]; then
    PATH="$PATH:$HOME/.local/bin"
fi

if [ -d "$HOME/.huff" ]; then
    PATH="$PATH:$HOME/.huff/bin"
fi

# TODO: don't default to ledger
# currently default to using ledger
export GNUPGHOME=~/.gnupg/ledger

function gpghome() {
    selection=$(echo "$HOME/.gnupg/ledger
$HOME/.gnupg
$HOME/.gnupg/trezor" | fzf)
    export GNUPGHOME="$selection"
}

# less options
export LESS='-R -C -M -I -j 10 -# 4'
# -C - make full screen reprints faster
# -M - display more info in status line
# -I - ignore casing in search
# -j 10 - display search results in line 10
# -# 4 - move 4 characters left/right on arrow key press

# source bash completions
if [ -d /usr/local/etc/bash_completion.d ]; then
    for filename in /usr/local/etc/bash_completion.d/*; do
        [ -e "$filename" ] || continue
        source "$filename"
    done
fi

if [ -f /usr/share/fzf/key-bindings.bash ]; then
    source /usr/share/fzf/key-bindings.bash
fi

if [ -f $(which direnv) ]; then
    eval "$(direnv hook bash)"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Setup fzf
# ---------
if [[ ! "$PATH" == *$HOME/.fzf/bin* ]]; then
  export PATH="$PATH:$HOME/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "$HOME/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "$HOME/.fzf/shell/key-bindings.bash"

