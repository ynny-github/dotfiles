#!/bin/bash

if [ -f /.dockerenv ]; then
    #TODO: I will write install commands each OS.
    # debian
    apt update
    apt install -y fish curl
fi

# Setup chezmoi
curl -fsLS chezmoi.io/get -- init --apply https://github.com/ynny-github/dotfiles.git
