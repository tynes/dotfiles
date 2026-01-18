#!/usr/bin/env bash

# Exit if not running interactively
[[ $- != *i* ]] && return

for file in $HOME/.bash/*; do
	source $file
done