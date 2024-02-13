#!/bin/bash
set -e -o pipefail

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
fi

if [ ! -d ~/.config ]; then
    mkdir -p ~/.config
fi

if [ ! -d ~/.config/mise ]; then
    mkdir -p ~/.config/mise
fi

cp exclude/mise/config.toml ~/.config/mise/config.toml
if [ ! -d ~/.local/bin/mise ]; then
    curl https://mise.run | sh
fi
eval "$(~/.local/bin/mise activate bash)"
mise install -y

# XXX: it is very inefficiency because this cloning run twice.
mise exec chezmoi@latest -- chezmoi init --apply ynny-github


mise_path=$(which mise)
if [ ! -f ~/.bashrc ]; then
    touch ~/.bashrc
fi
cat << EOF >> ~/.bashrc
# DO NOT EDIT
eval "\$($mise_path activate bash)"
# DO NOT EDIT
EOF

if [ ! -f ~/.zshrc ]; then
    touch ~/.zshrc
fi
cat << EOF >> ~/.zshrc
# DO NOT EDIT
eval "\$($mise_path activate zsh)"
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

if [ ! -f ~/.zprofile ]; then
    touch ~/.zprofile
fi
cat << EOF >> ~/.zprofile
# DO NOT EDIT
exec fish
# DO NOT EDIT
EOF
