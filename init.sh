#!/bin/sh

cd ~
git clone https://github.com/ynny-github/dotfiles.git

cd dotfiles
# clone すると実行権限が消えるため，シェンバで実行はやめておく
fish install.fish
