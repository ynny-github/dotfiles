local RemapFunctionKey(key) = {
    "type": "basic",
    "from": {
        "key_code": key,
        "modifiers": {
            "optional": [
                "any"
            ]
        }
    },
    "to": [
        {
            "key_code": key
        }
    ],
    "conditions": [
        {
            "type": "frontmost_application_if",
            "file_paths": [
                "ck2\\.app",
                "eu4\\.app"
            ],
            "bundle_identifiers": [
                "com.microsoft.VSCode"
            ]
        }
    ]
};

{
    "title": "Function keys work as fn keys",
    "rules": [
        {
            "description": "Function keys work as fn keys",
            "manipulators": [
                RemapFunctionKey("f1"),
                RemapFunctionKey("f2"),
                RemapFunctionKey("f3"),
                RemapFunctionKey("f4"),
                RemapFunctionKey("f5"),
                RemapFunctionKey("f6"),
                RemapFunctionKey("f7"),
                RemapFunctionKey("f8"),
                RemapFunctionKey("f9"),
                RemapFunctionKey("f10"),
                RemapFunctionKey("f11"),
                RemapFunctionKey("f12")
            ]
        }
    ]
}
