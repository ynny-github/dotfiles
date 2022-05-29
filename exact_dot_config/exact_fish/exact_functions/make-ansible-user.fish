function make-ansible-user
    useradd -m ansible
    passwd ansible
    
    mkdir /home/ansible/.ssh
    echo $argv > /home/ansible/.ssh/authorized_keys

    chown -R ansible:ansible /home/ansible/.ssh
    chmod 700 /home/ansible/.ssh
    chmod 600 /home/ansible/.ssh/authorized_keys
end