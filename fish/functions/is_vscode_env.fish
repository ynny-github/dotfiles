function is_vscode_env
    # USES_VSCODE_SERVER_SPAWN は Remote 系の拡張を使用するとき
    # セットされる環境変数の一つである
    if [ -n $USES_VSCODE_SERVER_SPAWN ]
        return 1
    end

    return 0
end