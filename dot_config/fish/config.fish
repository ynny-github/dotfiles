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
    ~/.local/bin/mise activate fish | source
    mise hook-env -s fish | source
    mise complete -s fish | source
end

if exist_cmd starship
    starship init fish | source
end


abbr --add s sudo
abbr --add se sudoedit
abbr --add edit-dotfiles code ~/.local/share/chezmoi


switch $CID
    case "main-macbook"
        # must absolute path
        set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

        fish_add_path /opt/homebrew/bin

        # because mac can't open code.
        set editor_path (which micro)
        set -gx EDITOR "$editor_path"
        set -gx SUDO_EDITOR "$editor_path"

        # Open Xcode from cmd
        alias xcode="open -a /Applications/Xcode.app"

        set -gx GOOGLE_DRIVE "$HOME/Google Drive/My Drive"# other commands for other hostname

        if test "$VSCODE_RESOLVING_ENVIRONMENT" = 1
            mise activate fish --shims | source
        else if status is-interactive
            mise activate fish | source
        else
            mise activate fish --shims | source
        end

    case "working-mac"
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

    case "*"
        # remote development settings
        if test is_remote_container; or test is_remote_ssh
            # sudoedit のエディタを vscode に変更
            set code_path (which code)
            set -gx SUDO_EDITOR "$code_path --wait"
            set -gx EDITOR "$code_path --wait"

        else if is_wsl
            # ユーザ空間のプログラムの保存先
            set PATH $HOME/.local/bin $PATH
            # Settings for WSL
            # key agent
            if ! pgrep gpg-agent > /dev/null;
                gpg-agent --homedir /home/yn/.gnupg --daemon > /dev/null
            end
            if [ -z $SSH_AUTH_SOCK ]
                set -U SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
            end
            alias vivaldi /mnt/c/users/ynnys/AppData/Local/Vivaldi/Application/vivaldi.exe
            alias psh /mnt/c/Windows/System32/WindowsPowerShell/v1.0//powershell.exe
            # 引数として -ArgumentList '-Command ~' を与えてやれば，~ を実行してくれる
            alias psh-admin "/mnt/c/Windows/System32/WindowsPowerShell/v1.0//powershell.exe Start-Process powershell.exe -Verb RunAs"
            # 自分の公開鍵を取得する
            alias gpk "curl -s https://github.com/yn-git.keys | clip.exe"
            alias sshfordocker "ssh -NL localhost:23750:/var/run/docker.sock docker-host &"
            alias cmd_to_deploy_dotfiles "echo 'git clone https://github.com/ynny-github/dotfiles.git && cd dotfiles && ./install.fish' | clip.exe "end
            alias cc "/mnt/c/Users/yn/scoop/apps/python/current/python.exe ~/.local/bin/custom_command.py"

            cd ~
        end
end
