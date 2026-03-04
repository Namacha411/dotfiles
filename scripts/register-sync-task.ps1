# 管理者権限で一度だけ実行してください
# Usage: .\scripts\register-sync-task.ps1

$scriptPath = Join-Path $PSScriptRoot "update-locks.ps1"
$taskName = "DotfilesSyncLocks"

$action = New-ScheduledTaskAction `
    -Execute "pwsh.exe" `
    -Argument "-NonInteractive -File `"$scriptPath`""

# 毎週月曜日 09:00 に実行
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "09:00"

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10) `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Update scoop/winget lock files" `
    -RunLevel Limited `
    -Force

Write-Host "[OK]    Task '$taskName' registered (weekly, Monday 09:00)"
Write-Host "        Manage in: taskschd.msc"
