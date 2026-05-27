# Usage:
#   nix profile add --file nix/packages.nix
{ pkgs ? import <nixpkgs> {} }:
with pkgs; [
  # --- Shell utilities (bash/.bashrc) ---
  eza          # ls の代替 (alias ls, ll)
  bat          # cat の代替 (alias cat)
  fd           # find の代替 (alias find)
  zoxide       # cd の代替 (z コマンド)
  starship     # プロンプト
  ghq          # リポジトリ管理 (cdg 関数)
  fzf          # ファジーファインダー (cdg 関数)

  # --- Development ---
  git
  go           # GOPATH は ~/.bashrc で設定済み
  bun          # PATH に ~/.bun/bin を追加済み
  uv           # Python パッケージマネージャー
  rustup       # Rust ツールチェーン管理 (rustc/cargo は rustup install stable で別途取得)

  # --- Neovim (nvim/README.md) ---
  neovim
  tree-sitter  # tree-sitter-manager によるパーサーコンパイル
  gcc          # tree-sitter パーサーのビルド
  ripgrep      # live grep (grepprg = "rg --vimgrep")

  # --- Fonts ---
  cascadia-code  # MS 公式。NF グリフ込み
]
