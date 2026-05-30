#!/bin/bash
set -e -o pipefail

exist_cmd() {
    command -v "$1" &>/dev/null
}

OS="$(uname -s)"

if [ "${OS}" = "Linux" ]; then
    if ! exist_cmd chezmoi; then
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
    fi
    export PATH="${HOME}/.local/bin:${PATH}"
else
    if ! exist_cmd chezmoi; then
        echo "Error: chezmoi is not installed. Please install it first." >&2
        echo "  macOS: brew install chezmoi" >&2
        exit 1
    fi
fi

chezmoi init --apply ynny-github
