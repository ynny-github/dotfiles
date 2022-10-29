# main mac ID is main-macbook.
if test "$CID" = "main-macbook"
    # must absolute path
    set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

    # Python Settings
    set -x PYENV_ROOT $HOME/.pyenv
    set -x PATH  $PYENV_ROOT/bin $PATH
    pyenv init - | source

    fish_add_path /opt/homebrew/bin

    # because mac can't open code.
    set editor_path (which micro)
    set -gx EDITOR "$editor_path"
    set -gx SUDO_EDITOR "$editor_path"

    # Open Xcode from cmd
    alias xcode="open -a /Applications/Xcode.app"

    # Written by app
    test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish
end
