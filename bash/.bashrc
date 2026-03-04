# PATH
export GOPATH="$HOME/go"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$GOPATH/bin:$PATH"

# vi mode
set -o vi

# Aliases
# Ubuntu uses 'eza' directly if installed from eza-community repo
alias ls='eza --icons'
alias ll='eza -a --icons --long'

# Ubuntu: bat is installed as 'batcat', fd as 'fdfind'
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
  alias bat='batcat'
fi
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
  alias fd='fdfind'
fi

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

rmrf() {
  rm -rf "$@"
}

cdg() {
  cd "$(ghq root)/$(ghq list | fzf)"
}

# Shell integrations
eval "$(starship init bash)"
eval "$(zoxide init bash)"

# Override cd to use zoxide and show directory listing
cd() {
  z "$@" && eza --icons
}
