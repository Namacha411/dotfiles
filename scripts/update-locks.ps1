$root = Split-Path -Parent $PSScriptRoot

Write-Host "[INFO]  Updating scoop lock..."
scoop export | Out-File -FilePath "$root\windows\packages\scoop\scoopfile.json" -Encoding UTF8
Write-Host "[OK]    windows\packages\scoop\scoopfile.json updated"

Write-Host "[INFO]  Updating winget lock..."
winget export -o "$root\windows\packages\winget\packages.json" --include-versions --accept-source-agreements
Write-Host "[OK]    windows\packages\winget\packages.json updated"
