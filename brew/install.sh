#!/bin/bash

. shared.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f $DIR/$BREW_FILE || ! -f $DIR/$CASK_FILE ]]; then
    echo "necessary files not found"
    echo "please run backup.sh"
    exit 1
fi

while read -r program; do
    echo "installing $program"
    brew install "$program"
done < "$DIR/$BREW_FILE"

while read -r program; do
    echo "installing $program"
    brew cask install "$program"
done < "$DIR/$CASK_FILE"

