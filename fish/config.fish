# 全環境設定
## fish 起動 message を削除
set fish_greeting ""
set PATH $HOME/.local/bin $PATH
set -x SHELL /usr/bin/fish

alias s sudo
alias se sudoedit
# direnv を使用できるようにする
eval (direnv hook fish)

# Remote Extension 時のみに実行
if [ -n is_vscode_env ]
    # sudoedit のエディタを vscode に変更
    set code_path (which code)
    set -gx SUDO_EDITOR "$code_path --wait"
    set -gx EDITOR "$code_path --wait"
end

# WSL 時のみ実行
if [ -n is_wsl ]
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
end