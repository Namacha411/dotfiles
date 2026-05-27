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

## Package Locks

Scoop and winget package lists are stored as lock files. To update them after installing/removing packages:

```powershell
.\scripts\update-locks.ps1
```
