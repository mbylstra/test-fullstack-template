#!/bin/bash

# Fetch latest commits from the template remote
git fetch template

# Merge template's main branch into current branch
git merge template/main
