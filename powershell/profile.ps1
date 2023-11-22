# Prompt
Invoke-Expression (&starship init powershell)
$OutputEncoding = [System.Text.Encoding]::GetEncoding('utf-8')

# PSReadLine
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineOption -HistoryNoDuplicates
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineKeyHandler -Key "Ctrl+f" -Function ForwardWord

# Alias
function _ls() {
  exa -a --icons
}
function ll() {
  exa -a --tree --icons --long
}
function touch() {
  New-Item -Type File $args
}
function cl($path) {
    cd $path && exa --icons
}

Set-Alias sudo gsudo
Set-Alias ls _ls
Set-Alias cat bat
Set-Alias find fd
Set-Alias od hexyl
Set-Alias ps procs
Set-Alias grep rg
Set-Alias unzip Expand-Archive

