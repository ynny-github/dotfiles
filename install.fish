#!/bin/fish
if [ ! -d ~/.config ]
    mkdir -p ~/.config
end

if [ ! -d ~/.config/direnv ]
    mkdir -p ~/.config/direnv
end

set PREFIX ~/dotfiles

ln -sf ~/$PREFIX/fish ~/.config/fish
ln -sf ~/$PREFIX/.textlintrc.json ~/.config/.textlintrc.json
ln -sf ~/$PREFIX/direnv ~/.config/direnv
