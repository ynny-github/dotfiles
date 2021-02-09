function mkfilewithadd
    touch $argv
    git add $argv

     # VScode 下で実行した場合，Window にコードを開く
    if [ -n $USES_VSCODE_SERVER_SPAWN ]
        code $argv
    end

end