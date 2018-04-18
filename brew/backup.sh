#!/bin/bash

. shared.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

which brew &>/dev/null || echo "homebrew not found"

echo "backing up brew install list"
if [ -f "$DIR/$BREW_FILE" ]; then
    echo "removing brew file, rebuilding..."
    rm "$DIR/$BREW_FILE"
    touch "$DIR/$BREW_FILE"
fi
for brew_item in $(brew list); do
    echo "$brew_item" >> "$DIR/$BREW_FILE"
done

brew cask &>/dev/null || echo "brew cask not found"

if [ -f "$DIR/$CASK_FILE" ]; then
    echo "removing brew cask file, rebuilding..."
    rm "$DIR/$CASK_FILE"
    touch "$DIR/$BREW_FILE"
fi
echo "backing up brew cask install list"
for cask_item in $(brew cask list); do
    echo "$cask_item" >> "$DIR/$CASK_FILE"
done
