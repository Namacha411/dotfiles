# env.nu
#
# Installed by:
# version = "0.113.1"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.
$env.PATH = ($env.PATH | prepend ($nu.home-dir | path join ".local" "bin"))

# Nushell resolves external commands by walking $env.PATH fresh on every
# invocation (no cross-call caching), unlike PowerShell's cached command
# lookup. Moving frequently used scoop shims to the front of the nu-local
# PATH shortens that per-call walk.
$env.PATH = ($env.PATH | prepend ($nu.home-dir | path join "scoop" "shims"))

zoxide init nushell | save -f ~/.zoxide.nu
