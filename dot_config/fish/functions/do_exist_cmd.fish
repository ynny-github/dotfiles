function do_exist_cmd
    if type $argv >/dev/null 2>&1
        return 0
    else
        return 1
    end
end
