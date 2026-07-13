# config.nu
#
# Installed by:
# version = "0.113.1"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R
$env.config.show_banner = false

$env.config.hooks.display_output = {|| table --icons }
$env.config.hooks = {
    env_change: {
        PWD: [{|before, after| ls | table --icons | print }]
    }
}

$env.config.buffer_editor = "nvim"
$env.config.table.mode = "light"
$env.config.table.trim = {
    methodology: "truncating"
    wrapping_try_keep_words: true
}
$env.config.footer_mode = "never"

$env.config.completions = {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "fuzzy"
}

$env.PROMPT_COMMAND_RIGHT = ""
$env.PROMPT_COMMAND = {||
    let shell_name = "nu"

    let dir = match (do --ignore-errors { $env.PWD | path relative-to $nu.home-dir }) {
        null => $env.PWD
        "" => "~"
        $relative_pwd => ([~ $relative_pwd] | path join)
    }

    let git_result = (git branch --show-current | complete)
    let git_part = if ($git_result.exit_code == 0 and ($git_result.stdout | str trim) != "") {
        $" (ansi yellow)\(($git_result.stdout | str trim)\)(ansi reset)"
    } else {
        ""
    }

    let shell_part = $"(ansi purple_bold)[($shell_name)](ansi reset)"
    let dir_part = $"(ansi cyan_bold)($dir)(ansi reset)"
    let time_part = $"(ansi white_dimmed)(date now | format date '%H:%M:%S')(ansi reset)"

    $"($shell_part) ($dir_part)($git_part)\n($time_part) "
}
$env.PROMPT_INDICATOR = $"(ansi green_bold)>(ansi reset) "

def ":q" [] {
    exit
}
def --env ghq-fzf [] {
    let root = (ghq root | str trim)
    let repo = (ghq list | fzf | str trim)
    if ($repo | is-empty) {
        return
    }
    cd ($root | path join $repo)
}
def gb-fzf [] {
    let branch = (
        git branch -a
        | fzf
        | str trim
        | str replace -r '^\* ' ''
        | str replace -r '^remotes/[^/]+/' ''
    )
    if not ($branch | is-empty) {
        git checkout $branch
    }
}

source ~/.zoxide.nu
