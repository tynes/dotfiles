#!/bin/bash

# Environment variables and PATH setup
# This file is sourced once per login shell

# Pager and editor
export PAGER=nvimpager

# Starship config
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

# less options
export LESS='-R -C -M -I -j 10 -# 4'
# -C - make full screen reprints faster
# -M - display more info in status line
# -I - ignore casing in search
# -j 10 - display search results in line 10
# -# 4 - move 4 characters left/right on arrow key press

if command -v nvim &> /dev/null; then
    export EDITOR=nvim
fi

# Java (Homebrew OpenJDK on macOS, Adoptium on Linux)
if [ -d /opt/homebrew/opt/openjdk@21 ]; then
    export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
elif [ -d /usr/lib/jvm/temurin-21-jdk-amd64 ]; then
    export JAVA_HOME="/usr/lib/jvm/temurin-21-jdk-amd64"
fi

# PATH setup
# homebrew - add to PATH first so brew command works
if [ -d /opt/homebrew/bin ]; then
    PATH="/opt/homebrew/bin:$PATH"
fi

# Java - ensure Homebrew OpenJDK is on PATH (symlinked into homebrew prefix)
if [ -n "$JAVA_HOME" ] && [ -d "$JAVA_HOME/bin" ]; then
    PATH="$JAVA_HOME/bin:$PATH"
fi

# import foundry tooling
if [ -d "$HOME/.foundry/bin" ]; then
    PATH="$PATH:$HOME/.foundry/bin"
fi

# bun
if [ -d "$HOME/.bun/bin" ]; then
    PATH="$PATH:$HOME/.bun/bin"
fi

# cargo rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

if [ -d /usr/local/bin ]; then
    PATH="$PATH:/usr/local/bin"
fi

if [ -d /usr/local/go/bin ]; then
    PATH="$PATH:/usr/local/go/bin"
fi

# this is the bin at the root of the repo
if [ -d "$HOME/bin" ]; then
    PATH="$PATH:$HOME/bin"
fi

if [ -d "$HOME/.local/bin" ]; then
    PATH="$PATH:$HOME/.local/bin"
fi

# ssh-agent (run once per login)
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
fi

# Export PATH
export PATH
