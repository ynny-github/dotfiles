# All Environment Settings

# remove greeting message
set fish_greeting ""

abbr --add s sudo
abbr --add se sudoedit
abbr --add edit-dotfiles code ~/.local/share/chezmoi

if command -v rtx > /dev/null
    rtx activate fish | source
    rtx hook-env -s fish | source
    rtx complete -s fish | source
end

if command -v starship > /dev/null
    starship init fish | source
end
