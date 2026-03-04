#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

info()    { echo "[INFO]  $*"; }
success() { echo "[OK]    $*"; }
warn()    { echo "[WARN]  $*"; }

# make_link <src> <dst>
make_link() {
  local src="$1"
  local dst="$2"

  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    info "Symlink already correct: $dst -> $src"
    return
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local bak="${dst}.bak.${TIMESTAMP}"
    warn "Backing up existing $dst -> $bak"
    mv "$dst" "$bak"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  success "Linked: $dst -> $src"
}

create_symlinks() {
  info "Creating symlinks..."

  make_link "$DOTFILES_DIR/nvim"                       "$HOME/.config/nvim"
  make_link "$DOTFILES_DIR/starship/starship.toml"     "$HOME/.config/starship.toml"
  make_link "$DOTFILES_DIR/wezterm/.wezterm.lua"       "$HOME/.wezterm.lua"
  make_link "$DOTFILES_DIR/vim/.vimrc"                 "$HOME/.vimrc"
  make_link "$DOTFILES_DIR/cc/common-rules.md"         "$HOME/.claude/CLAUDE.md"
  make_link "$DOTFILES_DIR/cc/settings.json"           "$HOME/.claude/settings.json"
  make_link "$DOTFILES_DIR/cc/statusline-command.sh"   "$HOME/.claude/statusline-command.sh"
  make_link "$DOTFILES_DIR/cc/skills"                  "$HOME/.claude/skills"
}

configure_shell() {
  local source_line="source \"$DOTFILES_DIR/bash/.bashrc\""
  local shell_rc

  case "$SHELL" in
    */zsh)  shell_rc="$HOME/.zshrc" ;;
    */bash) shell_rc="$HOME/.bashrc" ;;
    *) warn "Unknown shell: $SHELL. Defaulting to ~/.bashrc"; shell_rc="$HOME/.bashrc" ;;
  esac

  if grep -qF "$source_line" "$shell_rc" 2>/dev/null; then
    info "Shell config already sourced in $shell_rc"
  else
    echo "" >> "$shell_rc"
    echo "# dotfiles" >> "$shell_rc"
    echo "$source_line" >> "$shell_rc"
    success "Added source line to $shell_rc"
  fi
}

info "Starting dotfiles setup..."
info "Dotfiles directory: $DOTFILES_DIR"

create_symlinks
configure_shell

success "Setup complete! Restart your shell or run: source ~/.bashrc"
