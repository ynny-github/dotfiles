function is_mac
    if test (uname -s) = "Darwin"
        return 0
    else
        return 1
    end
end