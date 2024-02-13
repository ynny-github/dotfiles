#!/bin/bash
set -e -o pipefail

./installer.sh
rm -rf ~/dotfiles
