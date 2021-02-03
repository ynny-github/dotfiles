#!/bin/fish
if [ ! -d ~/.config ]
    mkdir -p ~/.config
end

set PREFIX ~/dotfiles

ln -s $PREFIX/fish ~/.config/fish
ln -s $PREFIX/.textlintrc.json ~/.config/.textlintrc.json
