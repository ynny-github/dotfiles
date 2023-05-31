#!/bin/bash

exec_cmd_with_sudo () {
    if [ ${HOME} = "/root" ]; then
        $@
    else
        sudo $@
    fi
}

do_exist_cmd () {
    if type $1 &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# install required packages in container
if [ -f /.dockerenv ]; then
    if do_exist_cmd "apt"; then
        exec_cmd_with_sudo apt update
        exec_cmd_with_sudo apt install -y fish curl
    elif do_exist_cmd "yum"; then
        exec_cmd_with_sudo yum update
        exec_cmd_with_sudo yum install -y fish curl
    fi
fi

if [ ! -d ~/.config/fish/completions ]; then
    mkdir -p ~/.config/fish/completions
fi

# setup asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.2
if [ -d ~/.asdf ]; then
    ln -s ~/.asdf/completions/asdf.fish ~/.config/fish/completions
fi
. "$HOME/.asdf/asdf.sh"

# setup chezmoi
asdf plugin add chezmoi
asdf install chezmoi latest
asdf global chezmoi latest
# XXX: it is very inefficiency because this cloning run twice.
chezmoi init --apply ynny-github

# setup direnv
asdf plugin add direnv
asdf install direnv latest
asdf global direnv latest

# setup starship
asdf plugin add starship
asdf install starship latest
asdf global starship latest

# setup jsonnet
asdf plugin add jsonnet
asdf install jsonnet latest
asdf global jsonnet latest

if [ ! -f ~/.bashrc ]; then
    touch ~/.bashrc
fi
cat << EOF >> ~/.bashrc
# DO NOT EDIT
. "$HOME/.asdf/asdf.sh"
source "${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/bashrc"
# DO NOT EDIT
EOF
