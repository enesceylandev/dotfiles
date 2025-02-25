#!/usr/bin/env bash

''find . -type d -print | fzf | xargs -I {} sh -c "cd '{}' && nvim" ''
