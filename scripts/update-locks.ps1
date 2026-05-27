$root = Split-Path -Parent $PSScriptRoot

Write-Host "[INFO]  Updating scoop lock..."
scoop export | Out-File -FilePath "$root\windows\scoop\scoopfile.json" -Encoding UTF8
Write-Host "[OK]    windows\scoop\scoopfile.json updated"

Write-Host "[INFO]  Updating winget lock..."
winget export -o "$root\windows\winget\packages.json" --include-versions --accept-source-agreements
Write-Host "[OK]    windows\winget\packages.json updated"
