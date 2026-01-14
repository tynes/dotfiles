#!/usr/bin/env bash

# GitHub CLI autocompletion
if command -v gh &> /dev/null; then
  eval "$(gh completion -s bash)"
fi

# Jujutsu (jj) CLI autocompletion
if command -v jj &> /dev/null; then
  eval "$(jj util completion bash)"
fi