# remote development settings
if is_remote_extension
    # sudoedit のエディタを vscode に変更
    set code_path (which code)
    set -gx SUDO_EDITOR "$code_path --wait"
    set -gx EDITOR "$code_path --wait"
end
