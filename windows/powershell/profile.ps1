# Prompt (zoxide init cached to avoid subprocess cost on every startup)
$_zoxideCache = "$env:TEMP\zoxide_init.ps1"
if (-not (Test-Path $_zoxideCache)) {
    zoxide init powershell | Out-File -Encoding UTF8 $_zoxideCache
}
. $_zoxideCache
Remove-Variable _zoxideCache

function prompt {
    $path = $PWD.Path -replace [regex]::Escape($HOME), '~'
    $branch = git branch --show-current 2>$null
    Write-Host $path -NoNewline -ForegroundColor Cyan
    if ($branch) {
        Write-Host " ($branch)" -NoNewline -ForegroundColor Yellow
    }
    Write-Host ""
    "> "
}

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

if ($Host.Name -eq 'ConsoleHost') {
    $psrlOpts = @{
        EditMode                   = 'Vi'
        HistorySavePath            = "$HOME\$($Host.Name)_history.txt"
        HistorySearchCursorMovesToEnd = $true
        PredictionSource           = 'History'
        PredictionViewStyle        = 'ListView'
        BellStyle                  = 'Visual'
    }
    if ($env:NVIM) {
        $psrlOpts['ViModeIndicator'] = 'None'
    } else {
        $psrlOpts['ViModeIndicator'] = 'Script'
        $psrlOpts['ViModeChangeHandler'] = $Function:__OnViModeChange
    }
    Set-PSReadLineOption @psrlOpts
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    # Ctrl+[ を Vi の Escape 相当にしたいが、Windows Console の制約で実現不可。
    # Ctrl+[ を押すと .NET の Console.ReadKey() は Ctrl+Oem4 として返すため、
    # PSReadLine が登録した 'Ctrl+[' ハンドラは永遠に呼ばれない。
    # PSReadLine issue #906 (未解決) 参照。
}

# Alias
Remove-Item alias:cd
Remove-Item alias:ls
Remove-Item alias:cat

function cd($Path="$HOME") {
  if ($Path -match '^-(\d+)$') {
    $upPath = ("../" * [int]$Matches[1]).TrimEnd('/')
    z $upPath && eza --icons
  } else {
    z $Path && eza --icons
  }
}
function .. {
  cd ..
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
function rmrf {
  Remove-Item -Recurse -Force $args
}
function :q() {
  Exit
}
function fghq {
    ghq list | fzf
}
function fgb {
    $branch = git branch -a | fzf | ForEach-Object { $_.Trim() -replace '^\* ', '' -replace '^remotes/[^/]+/', '' }
    if ($branch) {
        git checkout $branch
    }
}

Set-Alias cat bat
Set-Alias unzip Expand-Archive

# PATH
$Env:GOPATH = "$HOME\go"
$Env:PATH = "$HOME\.local\bin;$Env:PATH"
$Env:PATH = "$HOME\.bun\bin;$Env:PATH"
