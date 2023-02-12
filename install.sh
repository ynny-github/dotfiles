#!/bin/sh

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

# install fish
if [ -f /.dockerenv ]; then
    if do_exist_cmd "apt"; then
        exec_cmd_with_sudo apt update
        exec_cmd_with_sudo apt install -y fish
    elif do_exist_cmd "yum"; then
        exec_cmd_with_sudo yum update
        exec_cmd_with_sudo yum install -y fish
    fi
fi

# install chezmoi
if [ $(uname -s) = "Darwin" ]; then
    brew install chezmoi
else
    chmod +x chezmoi_installer.sh
    exec_cmd_with_sudo ./chezmoi_installer.sh
fi

# XXX: it is very inefficiency because this cloning run twice.
chezmoi init --apply ynny-github


if [ ! -d ~/.config/fish/completions ]; then
    mkdir -p ~/.config/fish/completions
fi

# setup asdf
if [ -d ~/.asdf ]; then
    ln -s ~/.asdf/completions/asdf.fish ~/.config/fish/completions
fi

rm -rf ~/dotfiles
