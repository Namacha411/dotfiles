# PATH
$Env:GOPATH = "$HOME\go"

# Prompt
$OutputEncoding = [System.Text.Encoding]::GetEncoding('utf-8')
Invoke-Expression (&starship init powershell)

# PSReadLine
Import-Module -Name CompletionPredictor

function _OnViModeChange() {
    if ($args[0] -eq 'Command') {
        # Set the cursor to a blinking block.
        Write-Host -NoNewLine "$([char]0x1b)[1 q"
    } else {
        # Set the cursor to a blinking line.
        Write-Host -NoNewLine "$([char]0x1b)[5 q"
    }
}
$AddToHistoryDelegate = {
    param([string]$line)
    switch -regex ($line) {
      "^[0-9]" { return $false }
      "^[a-z]$" { return $false }
      "exit" { return $false }
    }
    $sensitive = "password|asplaintext|token|key|secret|credential"
    return ($line -notmatch $sensitive)
}
Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -AddToHistoryHandler $AddToHistoryDelegate
Set-PSReadlineOption -HistoryNoDuplicates
Set-PSReadlineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler $Function:_OnViModeChange
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key "Ctrl+f" -Function ForwardWord

# Alias
function _ls() {
  eza -a --icons
}
function ll() {
  eza -a --tree --icons --long
}
function touch() {
  New-Item $args -Type File 
}
function cl($path) {
  Set-Location $path && eza --icons
}
function mkcd($dirName) {
  New-Item $dirName -ItemType Directory && Set-Location $dirName
}
function ..() {
  Set-Location ..
}
function ...() {
  Set-Location ../..
}
function ~() {
  Set-Location ~
}
function :q() {
  Exit
}
function :wq() {
  Exit
}

Set-Alias sudo gsudo
Set-Alias ls _ls
Set-Alias cat bat
Set-Alias find fd
Set-Alias od hexyl
Set-Alias ps procs
Set-Alias grep rg
Set-Alias unzip Expand-Archive

# Fzf setting
function ff() {
  return (fzf --preview "bat --color=always --style=header,grid --line-range :100 {}")
}

# func
function ktc($kt) {
  return (kotlinc $kt -include-runtime -d a.jar)
}

function ktrun($kt) {
  Write-Host "Compiling..."
  kotlinc $kt -include-runtime -d a.jar 
  if ($?) {
    Write-Host "Compiled!"
    java -jar a.jar
  }
  if ($?) {
    Remove-Item a.jar
  }
}
