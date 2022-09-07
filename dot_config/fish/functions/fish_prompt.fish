function _host_prompt
    if is_wsl
        set hn "wsl"
    else if is_remote_container
        set hn "container"
    else if is_colab
        set hn "colab"
    else if is_mac
        set hn "mac"
    else
        set hn $prompt_hostname
    end

    printf "%s %s\n" $hn $USER
end

function _path_prompt
    printf '%s\n' (realpath .)
end

function _prompt_git
    if not do_exist_cmd git
        return
    end

    if command git rev-parse --is-inside-work-tree >/dev/null 2>&1
        set -l git_branch (command git symbolic-ref HEAD 2> /dev/null | sed -e 's|^refs/heads/||')
        printf '%s\n' $git_branch
    end
end

# Main
function fish_prompt
    set -l last_pipestatus $pipestatus

    printf "\n"

    _host_prompt
    _path_prompt
    _prompt_git

    printf '> '
end
