# remote development settings
if test is_remote_container; or test is_remote_ssh
    # sudoedit のエディタを vscode に変更
    set code_path (which code)
    set -gx SUDO_EDITOR "$code_path --wait"
    set -gx EDITOR "$code_path --wait"
end
