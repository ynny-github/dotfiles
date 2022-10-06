# if status is-interactive
    # Commands to run in interactive sessions can go here
# end

# remove greeting message
set fish_greeting ""

alias s sudo
alias se sudoedit
# vagrant の debug レベル
# debug
# info  出力の量のバランスがいいらしい
# warn
# error
alias vagrant-with-detailerror "env VAGRANT_LOG=info vagrant"

alias history-all-delete "history clear"


# Settings for mac
if is_mac
    set PATH /opt/homebrew/bin $PATH
    alias assh-build="assh config build > ~/.ssh/config"

    # Setup GPG and ssh
    if ! pgrep gpg-agent > /dev/null;
        gpgconf --launch gpg-agent
    end
    # if [ -z $SSH_AUTH_SOCK ]
    #    set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
    # end
    set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)

    # set code_path (which code)
    # set -gx SUDO_EDITOR "$code_path --wait"
    # set -gx EDITOR "$code_path --wait"

    # code で開けないため、micro で対応
    set editor_path (which micro)
    set -gx EDITOR "$editor_path"
    set -gx SUDO_EDITOR "$editor_path"

    # Open Xcode from cmd
    alias xcode="open -a /Applications/Xcode.app"

    # Python Settings
    set -x PYENV_ROOT $HOME/.pyenv
    set -x PATH  $PYENV_ROOT/bin $PATH
    pyenv init - | source
    
    # Written by app
    test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish
    ### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
    set --export --prepend PATH "/Users/yn/.rd/bin"
    ### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
end

# settings for vscode remote extension
if is_remote_extension
    # sudoedit のエディタを vscode に変更
    set code_path (which code)
    set -gx SUDO_EDITOR "$code_path --wait"
    set -gx EDITOR "$code_path --wait"
end


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

# colab
if is_colab
    cd ~/gdrive/MyDrive/colab_dev/Projects
end
