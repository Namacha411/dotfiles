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

Copied from commit [`be42637`](https://github.com/addyosmani/agent-skills/commit/be42637c5af93fdc8526b68ec2f2651b930f316c). Not auto-updated — update manually by re-copying from the upstream repo after reviewing changes.

`shared/claude/skills/references/` holds shared checklist files that some skills link to. Upstream places these two directories up from each skill (`../../references/`), but here `shared/claude/skills/` is symlinked to `~/.claude/skills` as a single unit, so links were rewritten to `../references/` (one level up) to resolve correctly.

## Package Locks

Scoop and winget package lists are stored as lock files. To update them after installing/removing packages:

```powershell
.\scripts\update-locks.ps1
```
