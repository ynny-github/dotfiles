# All Environment Settings

# remove greeting message
set fish_greeting ""

abbr --add s sudo
abbr --add se sudoedit

if test -f ~/.asdf/asdf.fish
    source ~/.asdf/asdf.fish
end

if command -v direnv > /dev/null
    direnv hook fish | source
end
