function ln($src, $dst) {
  $current = (Get-Location).Path
  $value = Join-Path -Path $current -ChildPath $src
  New-Item -ItemType SymbolicLink -Path $dst -Value $value
}

function setupscoop() {
  if ( -not ( Test-Path scoop ) ) {
    irm get.scoop.sh | iex
  }
  scoop install ./scoop/scoopfile.json
}

function makesymlink() {
  ln ./powershell/profile.ps1 $profile
  ln ./wezterm/.wezterm.lua $home/.wezterm.lua
  ln ./nvim $env:LOCALAPPDATA/nvim
  ln ./starship/starship.toml $home/.config/starship.toml
}

setupscoop
makesymlink
