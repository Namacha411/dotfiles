#Requires -RunAsAdministrator

$root = Split-Path -Parent $PSScriptRoot

function New-Symlink($src, $dst) {
  $target = Join-Path -Path $root -ChildPath $src

  # Already a correct symlink — skip
  if (Test-Path $dst) {
    $item = Get-Item $dst -Force
    if ($item.LinkType -eq 'SymbolicLink' -and $item.Target -eq $target) {
      Write-Host "[INFO]  Symlink already correct: $dst -> $target"
      return
    }

    # Backup existing
    $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
    $bak = "$dst.bak.$timestamp"
    Write-Host "[WARN]  Backing up existing $dst -> $bak"
    Move-Item -Path $dst -Destination $bak -Force
  }

  $parent = Split-Path -Parent $dst
  if (-not (Test-Path $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }

  New-Item -ItemType SymbolicLink -Path $dst -Value $target | Out-Null
  Write-Host "[OK]    Linked: $dst -> $target"
}

function Set-Symlinks {
  New-Symlink powershell\profile.ps1      $PROFILE
  New-Symlink wezterm\.wezterm.lua        "$HOME\.wezterm.lua"
  New-Symlink nvim                        "$env:LOCALAPPDATA\nvim"
  New-Symlink starship\starship.toml      "$HOME\.config\starship.toml"
  New-Symlink cc\common-rules.md          "$HOME\.claude\CLAUDE.md"
  New-Symlink cc\settings.json            "$HOME\.claude\settings.json"
  New-Symlink cc\statusline-command.sh    "$HOME\.claude\statusline-command.sh"
  New-Symlink cc\skills                   "$HOME\.claude\skills"
}

Set-Symlinks
