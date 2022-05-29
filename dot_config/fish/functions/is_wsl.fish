function is_wsl
    # wsl
    if string length -q -- $WSL_DISTRO_NAME
        return 0
    # not wsl
    else
        return 1
    end
end
