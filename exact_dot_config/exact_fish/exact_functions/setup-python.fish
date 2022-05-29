function setup-python
    poetry new .

    # TODO: version 指定ができるようにする
    python -m .venv
    cp ~/dotfiles/python/.envrc {$PWD}/.envrc

    poetry add -D flake8 autopep8

end