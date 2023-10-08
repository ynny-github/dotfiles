#!/bin/bash

exec_as_root () {
    if [ ${HOME} = "/root" ]; then
        $@
    else
        sudo $@
    fi
}

exist_cmd () {
    if type $1 &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# install required packages in container
if [ -f /.dockerenv ]; then
    if exist_cmd "apt"; then
        exec_as_root apt update
        exec_as_root apt install -y fish curl git
    elif exist_cmd "yum"; then
        exec_as_root yum update
        exec_as_root yum install -y fish curl git
    fi

    if ! exist_cmd "rtx"; then
        curl https://rtx.pub/install.sh | sh
    fi
    eval "$(~/.local/share/rtx/bin/rtx activate bash)"
fi

if [ ! -d ~/.config ]; then
    mkdir -p ~/.config
fi

if [ ! -d ~/.config/rtx ]; then
    mkdir -p ~/.config/rtx
fi
cp dot_config/rtx/config.toml ~/.config/rtx/config.toml
rtx install -y

# XXX: it is very inefficiency because this cloning run twice.
rtx exec chezmoi@latest -- chezmoi init --apply ynny-github


rtx_path=$(which rtx)
if [ ! -f ~/.bashrc ]; then
    touch ~/.bashrc
fi
cat << EOF >> ~/.bashrc
# DO NOT EDIT
eval "\$($rtx_path activate bash)"
# DO NOT EDIT
EOF

if [ ! -f ~/.zshrc ]; then
    touch ~/.zshrc
fi
cat << EOF >> ~/.zshrc
# DO NOT EDIT
eval "\$($rtx_path activate zsh)"
# DO NOT EDIT
EOF

if [ ! -f ~/.bash_profile ]; then
    touch ~/.bash_profile
fi
cat << EOF >> ~/.bash_profile
# DO NOT EDIT
exec fish
# DO NOT EDIT
EOF

if [ ! -f ~/.zshprofile ]; then
    touch ~/.zshprofile
fi
cat << EOF >> ~/.zshprofile
# DO NOT EDIT
exec fish
# DO NOT EDIT
EOF
