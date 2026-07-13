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
  New-Symlink windows\powershell\profile.ps1      $PROFILE
  New-Symlink shared\nu\config.nu                 "$env:APPDATA\nushell\config.nu"
  New-Symlink shared\nu\env.nu                    "$env:APPDATA\nushell\env.nu"
  New-Symlink shared\wezterm.lua                  "$HOME\.wezterm.lua"
  New-Symlink shared\nvim                         "$env:LOCALAPPDATA\nvim"
  New-Symlink shared\starship.toml                "$HOME\.config\starship.toml"
  New-Symlink shared\claude\common-rules.md       "$HOME\.claude\CLAUDE.md"
  New-Symlink shared\claude\settings.json         "$HOME\.claude\settings.json"
  New-Symlink shared\claude\statusline-command.sh "$HOME\.claude\statusline-command.sh"
  New-Symlink shared\claude\skills                "$HOME\.claude\skills"
  New-Symlink shared\claude\hooks                 "$HOME\.claude\hooks"
  New-Symlink shared\claude\ccstatusline          "$HOME\.config\ccstatusline"
}

function Update-HookPaths {
  $settingsFile = Join-Path $root "shared\claude\settings.json"
  $hookPath = ($HOME -replace '\\', '/') + "/.claude/hooks/tts_hook.py"
  $content = Get-Content $settingsFile -Raw -Encoding UTF8
  $updated = $content -replace '[A-Za-z]:/[^"]+/\.claude/hooks/tts_hook\.py', $hookPath
  if ($content -ne $updated) {
    Set-Content $settingsFile $updated -Encoding UTF8 -NoNewline
    Write-Host "[OK]    Updated hook path in settings.json -> $hookPath"
  } else {
    Write-Host "[INFO]  Hook path already correct in settings.json"
  }
}

Set-Symlinks
Update-HookPaths
