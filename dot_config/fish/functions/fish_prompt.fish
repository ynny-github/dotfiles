function fish_prompt --description 'Write out the prompt'
    set -l last_pipestatus $pipestatus

    # Time Zone settings
    set -g theme_date_timezone Asia/Tokyo
    set -g theme_date_format  "+%Y-%m-%d %H:%M"

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

    printf "\n"
    printf "%s %s [%s]\n" $hn $USER (date "+%m/%d/%Y %H:%M")
    printf '%s\n' (realpath .)
    printf '> '
end
