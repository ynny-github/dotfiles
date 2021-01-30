function is_wsl
    # WSL_DISTRO は WSL ならセットされる環境変数である
    if [ -n $WSL_DISTRO ]
        reutrn 1
    end

    return 0

end