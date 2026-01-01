# Nushell Config File

# mise
if ('~/.config/nushell/mise.nu' | path expand | path exists) {
    source ~/.config/nushell/mise.nu
}

# starship
if (which starship | is-not-empty) {
    mkdir ~/.cache/starship
    ^starship init nu | save --force ~/.cache/starship/init.nu
    use ~/.cache/starship/init.nu
}

source $"($nu.cache-dir)/carapace.nu"

# git completions
if ('~/.config/nushell/scripts/nu_scripts/custom-completions/git/git-completions.nu' | path expand | path exists) {
    use ~/.config/nushell/scripts/nu_scripts/custom-completions/git/git-completions.nu *
}

# aliases
alias s = sudo
alias se = sudoedit
alias edit-dotfiles = code ~/.local/share/chezmoi

# git commit with specific editor
def gca [...args] { 
    with-env { GIT_EDITOR: "agy --wait" } { git commit -e ...$args }
}

def gcc [...args] { 
    with-env { GIT_EDITOR: "code --wait" } { git commit -e ...$args }
}
