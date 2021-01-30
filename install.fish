#!/bin/fish
if [ ! -d ~/.config ]
    mkdir -p ~/.config
end

ln -s ~/dotfiles/fish ~/.config/fish