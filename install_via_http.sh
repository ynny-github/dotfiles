#!/bin/sh
set -e -o pipefail

cd ~
git clone https://github.com/ynny-github/dotfiles.git
cd dotfiles
chmod +x install.sh
./install.sh
