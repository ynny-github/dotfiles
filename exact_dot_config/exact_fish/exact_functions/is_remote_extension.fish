function is_remote_extension
    # 空か否か判定する
    if string length -q -- $USES_VSCODE_SERVER_SPAWN
        return 0
    else
        return 1
    end
end
