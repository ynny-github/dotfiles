# main mac ID is main-macbook.
if test "$CID" = "main-macbook"
    # must absolute path
    set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

    fish_add_path /opt/homebrew/bin

    # because mac can't open code.
    set editor_path (which micro)
    set -gx EDITOR "$editor_path"
    set -gx SUDO_EDITOR "$editor_path"

    # Open Xcode from cmd
    alias xcode="open -a /Applications/Xcode.app"

    set -gx GOOGLE_DRIVE "$HOME/Google Drive/My Drive"
end
