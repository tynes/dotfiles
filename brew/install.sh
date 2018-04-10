#!/bin/bash

. shared.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f $DIR/$BREW_FILE || ! -f $DIR/$CASK_FILE ]]; then
    echo "necessary files not found"
    echo "please run backup.sh"
    exit 1
fi

# TODO: do any programs have special installs?
for program in `ls $DIR/BREW_FILE`; do
    brew install $program
done

for cask_program in `ls $DIR/CASK_FILE`; do
    brew cask install $cask_program
done

