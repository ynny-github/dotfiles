#!/bin/fish
if [ ! -d ~/.config ]
    mkdir -p ~/.config
end

set PREFIX ~/dotfiles

ln -sf $PREFIX/fish/* ~/.config/fish/
ln -sf $PREFIX/.textlintrc.json ~/.config/.textlintrc.json
