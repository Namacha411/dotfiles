$root = Split-Path -Parent $PSScriptRoot

Write-Host "[INFO]  Updating scoop lock..."
scoop export | Out-File -FilePath "$root\scoop\scoopfile.json" -Encoding UTF8
Write-Host "[OK]    scoop\scoopfile.json updated"

Write-Host "[INFO]  Updating winget lock..."
winget export -o "$root\winget\packages.json" --include-versions --accept-source-agreements
Write-Host "[OK]    winget\packages.json updated"
