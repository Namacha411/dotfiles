# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles for Windows and Linux (Ubuntu). Configuration is managed via symlinks created by setup scripts.

## Setup Commands

**Windows** (requires Administrator):
```powershell
.\scripts\setup.ps1
```

**Linux/Ubuntu**:
```bash
./scripts/setup.sh
```

Both scripts create symlinks from the repo into the appropriate config locations. Existing files are backed up with a timestamp suffix before being replaced.

**Update package lock files** (Windows):
```powershell
.\scripts\update-locks.ps1
```

## Directory Structure

```
dotfiles/
├── linux/       # Linux-only configs
├── windows/     # Windows-only configs
├── shared/      # Cross-platform configs
└── scripts/     # Setup scripts
```

## Symlink Map

| Source (repo) | Destination |
|---|---|
| `shared/nvim/` | `%LOCALAPPDATA%\nvim` (Win) / `~/.config/nvim` (Linux) |
| `windows/powershell/profile.ps1` | `$PROFILE` (Win only) |
| `shared/wezterm.lua` | `~\.wezterm.lua` |
| `shared/starship.toml` | `~/.config/starship.toml` |
| `shared/claude/common-rules.md` | `~/.claude/CLAUDE.md` |
| `shared/claude/settings.json` | `~/.claude/settings.json` |
| `shared/claude/statusline-command.sh` | `~/.claude/statusline-command.sh` |
| `shared/claude/skills` | `~/.claude/skills` |
| `shared/claude/ccstatusline` | `~/.config/ccstatusline` |
| `linux/vim/.vimrc` | `~/.vimrc` (Linux only) |

The `linux/bash/.bashrc` is not symlinked; instead `setup.sh` appends a `source` line to the user's shell rc file.

## Architecture Notes

### `shared/claude/` — Claude Code Settings
- `common-rules.md` becomes the global `~/.claude/CLAUDE.md`
- `settings.json` becomes `~/.claude/settings.json`
- `skills/` contains custom slash-command skills (e.g., `skills/pr/SKILL.md`)
- Changes here affect Claude Code behavior globally once symlinked

### `shared/nvim/` — Neovim Config
- Plugin manager: lazy.nvim (bootstrapped in `init.lua`)
- Plugin configs live in `lua/plugins/` as individual files
- Core settings in `lua/config/` (options, keymaps, autocmds)
- Snippets in `snippets/` (VSCode-compatible JSON format, loaded via blink.cmp)

### `linux/bash/.bashrc` — Linux Shell
- `zoxide init` must run **before** the `cd()` override (which calls `z`)
- On Ubuntu, `bat` is installed as `batcat` and `fd` as `fdfind`; aliases handle this

### Package Locks
- `windows/packages/scoop/scoopfile.json` — Scoop packages (Windows)
- `windows/packages/winget/packages.json` — Winget packages (Windows)
- `linux/nix/packages.nix` — Nix packages (Linux)
- Regenerate Windows locks with `.\scripts\update-locks.ps1` after installing/removing packages

## Python Scripts

Use PEP 723 inline script metadata and run with `uv run`:

```python
# /// script
# dependencies = [
#   "package-name>=version",
# ]
# requires-python = ">=3.14"
# ///
```

Always use type hints with Python 3.9+ syntax (`list[str]`, `X | None`, etc.).
