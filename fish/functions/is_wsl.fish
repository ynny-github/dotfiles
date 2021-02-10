function is_wsl
    # WSL_DISTRO は WSL ならセットされる環境変数である
    if [ -n $WSL_DISTRO ]
        return 1
    end

    return 0

end