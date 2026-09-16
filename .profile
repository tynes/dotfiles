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

# gpg needs to know which terminal to draw pinentry on. Without this, signing a
# commit over ssh or inside tmux fails with "Inappropriate ioctl for device"
# rather than prompting for the passphrase.
if tty -s; then
    export GPG_TTY=$(tty)
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

# ssh-agent: one shared agent per machine, at a fixed socket path.
#
# This used to be `[ -z "$SSH_AUTH_SOCK" ] && eval "$(ssh-agent -s)"`, which
# spawned a brand new *empty* agent in every login shell. tmux starts each pane
# as a login shell, and macOS only exports the Keychain agent's socket into the
# GUI session (not into sshd sessions), so panes kept landing on fresh, keyless
# agents. A fixed path means every shell and pane converges on the same agent
# regardless of when it was created, and tmux's cached SSH_AUTH_SOCK can never
# go stale.
SSH_AGENT_SOCK="$HOME/.ssh/agent.sock"

# ssh-add -l exit codes: 0 = agent has keys, 1 = agent up but empty, 2 = no agent.
SSH_AUTH_SOCK="$SSH_AGENT_SOCK" ssh-add -l >/dev/null 2>&1
ssh_agent_state=$?

if [ "$ssh_agent_state" -eq 2 ]; then
    # Nothing listening. Clear the socket a dead agent left behind, then start one.
    rm -f "$SSH_AGENT_SOCK"
    ssh-agent -a "$SSH_AGENT_SOCK" >/dev/null 2>&1 && ssh_agent_state=1
fi

if [ "$ssh_agent_state" -ne 2 ]; then
    export SSH_AUTH_SOCK="$SSH_AGENT_SOCK"
    # `ssh-agent -a` prints a pid, but no shell here should be able to kill the
    # shared agent, and a stale pid in tmux's environment is worse than none.
    unset SSH_AGENT_PID
fi

if [ "$ssh_agent_state" -eq 1 ]; then
    # Agent is up but empty: load every private key that has a matching .pub.
    # Only runs once per agent lifetime, so a passphrase is asked for at most
    # once per boot rather than once per pane.
    for ssh_pub in "$HOME"/.ssh/*.pub; do
        ssh_key="${ssh_pub%.pub}"
        [ -f "$ssh_key" ] && ssh-add "$ssh_key" >/dev/null 2>&1
    done
    unset ssh_pub ssh_key
fi

unset ssh_agent_state

# Export PATH
export PATH

# .gitconfig signs every commit by default; this flips signing off in
# ~/.gitconfig.local on machines that don't hold the secret key (and warns), then
# back on once a key is imported. Runs here so the state re-derives every login.
if [ -x "$HOME/bin/git-signing-refresh" ]; then
    "$HOME/bin/git-signing-refresh"
fi
