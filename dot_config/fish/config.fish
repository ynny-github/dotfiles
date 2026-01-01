function exist_cmd
    if type $argv >/dev/null 2>&1
        return 0
    else
        return 1
    end
end

function is_remote_container
    if string length -q -- $REMOTE_CONTAINERS
        return 0
    else
        return 1
    end
end

function is_remote_ssh
    set output (ps aux | grep "code --extensionDevelopmentPath=.*/ms-vscode-remote.remote-ssh")
    if test -n "$output"
        return 0
    else
        return 1
    end
end

function is_wsl
    # wsl
    if string length -q -- $WSL_DISTRO_NAME
        return 0
    # not wsl
    else
        return 1
    end
end

# remove greeting message
set fish_greeting ""

if [ -f ~/.local/bin/mise ]
    mise hook-env -s fish | source
    mise complete -s fish | source

    if test "$VSCODE_RESOLVING_ENVIRONMENT" = 1
        mise activate fish --shims | source
    else if status is-interactive
        mise activate fish | source
    else
        mise activate fish --shims | source
    end
end

if exist_cmd starship
    starship init fish | source
end


abbr --add s sudo
abbr --add se sudoedit
abbr --add edit-dotfiles code ~/.local/share/chezmoi

# git commit with specific editor
function gca
    env GIT_EDITOR="agy --wait" git commit -e $argv
end

function gcc
    env GIT_EDITOR="code --wait" git commit -e $argv
end


fish_add_path ~/.antigravity/antigravity/bin
