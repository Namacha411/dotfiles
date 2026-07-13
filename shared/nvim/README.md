# Neovim Config

## Requirements

### Neovim

- **Neovim 0.12+**

### External tools

nix 部分はLLMによって作成、動作未確認

| Tool | 用途 | Windows (winget) | Linux/Mac (nix) |
|---|---|---|---|
| **git** | lazy.nvim のプラグイン取得、gitsigns | `winget install Git.Git` | `nix profile install nixpkgs#git` |
| **tree-sitter CLI** | tree-sitter-manager によるパーサーコンパイル | `winget install tree-sitter.tree-sitter` | `nix profile install nixpkgs#tree-sitter` |
| **C compiler** | tree-sitter パーサーのビルド | `winget install zig.zig` (`zig cc` を使用) | `nix profile install nixpkgs#gcc` |
| **fzf** | fzf-lua のファジーファインダー | `winget install junegunn.fzf` | `nix profile install nixpkgs#fzf` |
| **ripgrep** | live grep (`grepprg = "rg --vimgrep"`) | `winget install BurntSushi.ripgrep.MSVC` | `nix profile install nixpkgs#ripgrep` |
| **Cascadia Code NF** | アイコン表示 (nvim-web-devicons, blink.cmp) | - | `nix profile install nixpkgs#nerd-fonts.cascadia-code` |
| **Nushell (nu)** | Windows でのターミナル統合 | `winget install Nushell.Nushell` | - |

#### WSL のみ

| Tool | 用途 | インストール |
|---|---|---|
| **win32yank** | クリップボード連携 | パッケージマネージャー非対応。[リリースページ](https://github.com/equalsraf/win32yank/releases) から `win32yank.exe` を取得し `PATH` の通った場所に配置 (Windows 側) |

### LSP servers

Mason (`mason.nvim`) で管理。`:Mason` を開いて必要なサーバーをインストールする。

## Plugins

| Plugin | 役割 |
|---|---|
| lazy.nvim | プラグインマネージャー |
| tokyonight.nvim | カラースキーム |
| tree-sitter-manager.nvim | tree-sitter パーサー管理 (Neovim 0.12 ビルトイン未収録の言語) |
| aerial.nvim | treesitter ベースのアウトライン (fzf-lua 連携) |
| fzf-lua | ファジーファインダー |
| blink.cmp | 補完エンジン |
| mason.nvim + mason-lspconfig.nvim | LSP サーバー管理 |
| nvim-lspconfig | LSP 設定 |
| gitsigns.nvim | Git 差分表示・blame |
| oil.nvim | ファイルエクスプローラー |
| nvim-surround | テキストオブジェクト囲み操作 |
| which-key.nvim | キーバインドヘルプ |
| fidget.nvim | LSP 進捗表示 |
| ibl.nvim | インデントガイド |
| marks.nvim | マーク管理 |
| auto-save.lua | 自動保存 |

## Bundled parsers (Neovim 0.12)

以下は Neovim 0.12 に同梱されているため tree-sitter-manager での追加インストール不要:

`bash`, `c`, `lua`, `markdown`, `markdown_inline`, `python`, `query`, `vim`, `vimdoc`

## tree-sitter-manager で管理するパーサー

`rust`, `json`, `yaml`, `toml`, `csv`, `gitignore`, `html`

初回起動時に自動インストールされる (`ensure_installed`)。
