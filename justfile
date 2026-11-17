# Drive the dotfiles from here instead of calling the scripts directly.
# Run `just` to list the recipes.

set shell := ["bash", "-euo", "pipefail", "-c"]

# List the recipes
default:
    @just --list

# Install the tools, then link the dotfiles
bootstrap: install setup

# Install tools (all steps, or only the named ones: just install fzf jj)
install *steps:
    ./install.sh {{steps}}

# List the install steps for this OS
steps:
    ./install.sh --list

# Symlink the dotfiles into $HOME
setup:
    ./setup.sh

# Show what setup would change, without changing anything
plan:
    ./setup.sh --dry-run

# Lint every tracked shell script with shellcheck
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    files=()
    while IFS= read -r f; do
        [ -f "$f" ] || continue
        case "$f" in
            *.sh) files+=("$f") ;;
            *) if head -n 1 "$f" | grep -Eq '^#!.*[/ ](ba)?sh([[:space:]]|$)' ||
                    head -n 5 "$f" | grep -q '^# shellcheck shell='; then
                    files+=("$f")
                fi ;;
        esac
    done < <(git ls-files)
    echo "shellcheck: ${#files[@]} files"
    shellcheck "${files[@]}"

# Smoke-test setup.sh and install.sh against a throwaway $HOME
test:
    #!/usr/bin/env bash
    set -euo pipefail
    home=$(mktemp -d)
    trap 'rm -rf "$home"' EXIT
    export HOME="$home" XDG_STATE_HOME="$home/.local/state" XDG_CONFIG_HOME="$home/.config"
    echo "--- install.sh --list"
    ./install.sh --list >/dev/null
    echo "--- setup.sh --dry-run"
    ./setup.sh --dry-run
    echo "--- setup.sh"
    ./setup.sh
    [ -L "$HOME/.bashrc" ] || { echo "expected ~/.bashrc to be a symlink" >&2; exit 1; }
    echo "--- setup.sh again (should change nothing)"
    ./setup.sh

# Everything CI runs
ci: lint test
