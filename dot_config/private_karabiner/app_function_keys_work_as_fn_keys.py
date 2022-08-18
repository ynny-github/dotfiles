# -*- coding: utf-8 -*-
import json

def main():
    APP = [
        "com.microsoft.VSCode"
    ]

    with open("assets/complex_modifications/function_keys_work_as_fn_keys_specified_app.json", "r") as fp:
        setting = json.load(fp)

    rules = []
    for rule in setting["rules"][0]["manipulators"]:
        rule["conditions"][0]["bundle_identifiers"] = APP
        rules.append(rule)
    setting["rules"] = rules

    with open("assets/complex_modifications/function_keys_work_as_fn_keys_specified_app.json", "w") as fp:
        json.dump(setting, fp, indent=4)


if __name__ == '__main__':
    main()
