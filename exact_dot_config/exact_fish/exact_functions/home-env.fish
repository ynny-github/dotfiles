function home-env
    argparse -n home-env "p/push" "u/upgrade" -- $argv

    if set -lq _flag_push
        cd ~
        # 現在の監視対象
        # 監視対象を増やしたら追加する
        git add -f README.md
        git add -f init.sh
        git add -f .gitignore
        git add -f .gitconfig
        git add -f .config/fish/functions
        git add -f .config/fish/config.fish
        git add -f .config/micro
        git add -f .config/git

        git commit -m "pushed by home-env command"
        git push origin main
        #git diff --exit-code
        # 差分があったら実行
        #if test $status -eq 1
        #    git commit -m "pushed by home-env"
        #    git push origin main
        #end
    end

    if set -lq _flag_upgrade
        cd ~
        git pull
    end

end