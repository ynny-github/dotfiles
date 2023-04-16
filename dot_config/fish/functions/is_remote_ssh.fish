function is_remote_ssh
    set output (ps aux | grep "code --extensionDevelopmentPath=.*/ms-vscode-remote.remote-ssh")
    if test -n "$output"
        return 0
    else
        return 1
    end
end
