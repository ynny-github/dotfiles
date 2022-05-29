function build-ssh-config
    assh config build > ~/.ssh/config
    cp ~/.ssh/config /mnt/c/Users/ynnys/.ssh/
end