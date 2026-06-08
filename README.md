# dotfiles

## Structure

```
dotfiles/
├── linux/       # Linux-only configs (bash, vim, nix)
├── windows/     # Windows-only configs (powershell, packages)
├── shared/      # Cross-platform configs (nvim, starship, wezterm, claude)
└── scripts/     # Setup and maintenance scripts
```

## Setup

### Windows

```powershell
# Run as Administrator
.\scripts\setup.ps1
```

Creates symlinks for: PowerShell profile, WezTerm, Neovim, Starship, Claude Code settings.

### Linux (Ubuntu)

```bash
./scripts/setup.sh
```

Creates symlinks and installs Nix packages.

## Third-party Skills

`shared/claude/skills/` contains skills copied from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT License).

Copied from commit [`c076972`](https://github.com/addyosmani/agent-skills/commit/c076972e2626fe2acc30b00a6c7240d4c5fb786a). Not auto-updated — update manually by re-copying from the upstream repo after reviewing changes.

## Package Locks

Scoop and winget package lists are stored as lock files. To update them after installing/removing packages:

```powershell
.\scripts\update-locks.ps1
```
