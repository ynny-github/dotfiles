function is_remote_container
    if string length -q -- $REMOTE_CONTAINERS
        return 0
    else
        return 1
    end
end