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
if ! do_exist_cmd "rtx"; then
    curl https://rtx.pub/install.sh | sh
fi

cp dot_config/rtx/config.toml ~/.config/rtx/config.toml
rtx install -y

# XXX: it is very inefficiency because this cloning run twice.
chezmoi init --apply ynny-github

if [ ! -f ~/.bashrc ]; then
    touch ~/.bashrc
fi
cat << EOF >> ~/.bashrc
# DO NOT EDIT
eval "$(rtx activate bash)"
# DO NOT EDIT
EOF
