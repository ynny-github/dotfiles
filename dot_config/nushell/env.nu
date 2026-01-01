# Nushell Environment Config File

# mise
if ('~/.local/bin/mise' | path expand | path exists) {
    ^~/.local/bin/mise activate nu | save --force ~/.config/nushell/mise.nu
}

# SSH Auth Sock configuration
# Check for 1Password SSH agent first
let onepassword_sock = $"($env.HOME)/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if ($onepassword_sock | path exists) {
    $env.SSH_AUTH_SOCK = $onepassword_sock
}

# Carapace
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"