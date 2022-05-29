# OS に依存しないために、Rust に落とし込む
function g
    argparse -n g "t/tc" "a/ap" -- $argv

    if set -lq _flag_tc
        git add .
        git commit -m "[tmp commit] $argv"
    end

    if set -lq _flag_ap
        set branch (git rev-parse --abbrev-ref HEAD)

        if test $branch != "main"
            git add .
            git commit -m "automatically pushed for backup by command"
            git push origin $branch
        else
            echo "You can't push automatically on main branch"
        end

    end

end