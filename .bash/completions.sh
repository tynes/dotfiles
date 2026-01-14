#!/usr/bin/env bash

# GitHub CLI autocompletion
if command -v gh &> /dev/null; then
  eval "$(gh completion -s bash)"
fi
