# Nix
[ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ] && . "$HOME/.nix-profile/etc/profile.d/nix.sh"

# PATH
export GOPATH="$HOME/go"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$GOPATH/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# History
HISTCONTROL=ignoredups:erasedups
HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# Completion
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'

shopt -s autocd
shopt -s globstar
shopt -s cdspell

export EDITOR=nvim

# vi mode
set -o vi

# Aliases
alias ls='eza --icons'
alias ll='eza -a --icons --long'
alias cat='bat'
alias find='fd'

alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd ~'

alias :q='exit'

# Functions
mkcd() {
  mkdir -p "$1" && cd "$1"
}

cdg() {
  cd "$(ghq root)/$(ghq list | fzf)"
}

# Prompt
__prompt() {
  local path="${PWD/#$HOME/\~}"
  local branch
  branch="$(git branch --show-current 2>/dev/null)"
  PS1="\[\e[36m\]${path}\[\e[0m\]"
  if [ -n "$branch" ]; then
    PS1+=" \[\e[33m\](${branch})\[\e[0m\]"
  fi
  PS1+="\n> "
}

PROMPT_COMMAND=__prompt

# Shell integrations (must come after PROMPT_COMMAND so zoxide appends its hook)
eval "$(zoxide init bash)"

cd() {
  z "$@" && eza --icons
}
