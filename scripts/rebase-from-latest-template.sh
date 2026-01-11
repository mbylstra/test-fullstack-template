#!/bin/bash

# Fetch latest commits from the template remote
git fetch template

# Rebase current branch on template's main branch
git rebase template/main
