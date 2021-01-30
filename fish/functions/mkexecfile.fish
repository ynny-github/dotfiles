# 実行権限付きでファイルを作成する
function mkexecfile
    touch $argv
    chmod 750 $argv

    # VScode 下で実行した場合，Window にコードを開く
    if [ -n $USES_VSCODE_SERVER_SPAWN ]
        code $argv
    end

end