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

Synced with commit [`1401c8b`](https://github.com/addyosmani/agent-skills/commit/1401c8b8030e023baeebb31781a6653fe8e93026). Not auto-updated — update manually by re-copying from the upstream repo after reviewing changes.

Not copied from upstream: `references/orchestration-patterns.md` (it describes upstream's persona and slash-command layout, which this repo does not have) and the `doubt-driven-development` skill.

`shared/claude/skills/references/` holds shared checklist files that some skills link to. Upstream places these two directories up from each skill (`../../references/`), but here `shared/claude/skills/` is symlinked to `~/.claude/skills` as a single unit, so links were rewritten to `../references/` (one level up) to resolve correctly.

## Package Locks

Scoop and winget package lists are stored as lock files. To update them after installing/removing packages:

```powershell
.\scripts\update-locks.ps1
```
