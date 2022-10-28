# settings for wsl
if is_wsl
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
