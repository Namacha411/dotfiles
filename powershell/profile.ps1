# Prompt
Invoke-Expression (& { (starship init powershell --print-full-init | Out-String) })
Invoke-Expression (& { (zoxide init powershell | Out-String) })

$OutputEncoding = [System.Text.Encoding]::GetEncoding('utf-8')

# PSReadLine
function __OnViModeChange {
    if ($args[0] -eq 'Command') {
        # Set the cursor to a blinking block.
        Write-Host -NoNewLine "`e[1 q"
    } else {
        # Set the cursor to a blinking line.
        Write-Host -NoNewLine "`e[5 q"
    }
}
Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler $Function:__OnViModeChange
# https://github.com/PowerShell/PSReadLine/issues/906
Set-PSReadLineKeyHandler -Chord 'Ctrl+Oem4' -ViMode Insert -Function ViCommandMode

Set-PSReadLineOption -HistorySavePath "$HOME\$($Host.Name)_history.txt"
Set-PSReadlineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -PredictionSource HistoryAndPlugin

Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

Set-PSReadLineOption -BellStyle Visual

# Alias
Remove-Item alias:cd
Remove-Item alias:ls
Remove-Item alias:cat
Remove-Item alias:ps

function cd($Path="$HOME") {
  z $Path && eza --icons
}
function .. {
  cd ..
}
function ... {
  cd ../..
}
function ~ {
  cd ~
}
function ls {
  eza --icons
}
function ll {
  eza -a --icons --long
}
function touch {
  New-Item $args -Type File 
}
function mkcd($Path) {
  New-Item $Path -ItemType Directory && z $Path
}
function rmrf {
  Remove-Item -Recurse -Force $args
}
function :q() {
  Exit
}
function cdg {
    cd "$(ghq root)\$(ghq list | fzf)"
}

Set-Alias sudo gsudo
Set-Alias cat bat
Set-Alias find fd
Set-Alias od hexyl
Set-Alias ps procs
Set-Alias unzip Expand-Archive

# PATH
$Env:GOPATH = "$HOME\go"
$Env:PATH = "$HOME\.local\bin;$Env:PATH"
$Env:PATH = "$HOME\.bun\bin;$Env:PATH"
