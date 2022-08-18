function karabiner-elements
    argparse -n karabiner-elements "update-apps-using-fn-keys"
    cd ~/.config/karabiner

    if set -lq _flag_update-apps-using-fn-keys
        python3 app_function_keys_work_as_fn_keys.py
    end
end
