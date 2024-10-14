#!/usr/bin/env bash

source $HOME/.path.bash

for file in $HOME/.bash/*; do
	source $file
done