# mac to work ID is working-mac.
if test "$CID" = "working-mac"
    fish_add_path /opt/homebrew/bin
    # because mac can't open code.
    set editor_path (which micro)
    set -gx EDITOR "$editor_path"
    set -gx SUDO_EDITOR "$editor_path"

    if [ -z $SSH_AUTH_SOCK ]
        # Setup GPG and ssh
        if ! pgrep gpg-agent > /dev/null;
            gpgconf --launch gpg-agent
        end
        set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
    end


    # Written by app
    test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish
    set --export --prepend PATH "/Users/yn/.rd/bin"
end
