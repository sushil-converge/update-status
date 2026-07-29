<#
.SYNOPSIS
    Registers the daily STATUS.md update as a Windows Scheduled Task.

.DESCRIPTION
    Run this ONCE, from an elevated PowerShell prompt, after you've confirmed
    update-status.ps1 works via -DryRun.

    Creates a task named "Construction AI OS - Daily Status Update" that runs every
    weekday at the configured time under your own account.

.PARAMETER Time
    24-hour time to run, e.g. '18:00'.

.PARAMETER DaysOfWeek
    Which days to run. Default is weekdays only.

.EXAMPLE
    .\register-task.ps1
    .\register-task.ps1 -Time '17:30'
    .\register-task.ps1 -Time '18:00' -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday,Saturday

.NOTES
    To remove:  Unregister-ScheduledTask -TaskName 'Construction AI OS - Daily Status Update' -Confirm:$false
    To run now: Start-ScheduledTask   -TaskName 'Construction AI OS - Daily Status Update'
    To inspect: Get-ScheduledTaskInfo -TaskName 'Construction AI OS - Daily Status Update'
#>

[CmdletBinding()]
param(
    [string]$Time = '18:00',
    [string[]]$DaysOfWeek = @('Monday','Tuesday','Wednesday','Thursday','Friday'),
    [string]$ScriptPath = 'D:\Vault\Projects\Construction\project-status\scripts\update-status.ps1'
)

$ErrorActionPreference = 'Stop'
$TaskName = 'Construction AI OS - Daily Status Update'

if (-not (Test-Path -LiteralPath $ScriptPath)) {
    throw "Script not found: $ScriptPath"
}

# Prefer PowerShell 7 if present; fall back to Windows PowerShell.
$pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue)?.Source
if (-not $pwsh) { $pwsh = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" }

$action = New-ScheduledTaskAction `
    -Execute $pwsh `
    -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$ScriptPath`"" `
    -WorkingDirectory (Split-Path $ScriptPath -Parent)

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DaysOfWeek -At $Time

# RunOnlyIfNetworkAvailable: no point running if it can't push.
# StartWhenAvailable: if the laptop was asleep at 18:00, run at next wake.
# ExecutionTimeLimit: kill a hung run rather than leaving it overnight.
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable `
    -DontStopIfGoingOnBatteries `
    -AllowStartIfOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 30) `
    -MultipleInstances IgnoreNew

# Runs as you, interactively - so it reuses your existing `codex login` session.
# S4U/SYSTEM would not see your ~/.codex credentials.
$principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Limited

Register-ScheduledTask `
    -TaskName    $TaskName `
    -Action      $action `
    -Trigger     $trigger `
    -Settings    $settings `
    -Principal   $principal `
    -Description 'Runs Codex to update project-status/STATUS.md from component repo activity, then commits and pushes.' `
    -Force | Out-Null

Write-Host "Registered '$TaskName'"
Write-Host "  Runs:   $($DaysOfWeek -join ', ') at $Time"
Write-Host "  Script: $ScriptPath"
Write-Host "  Shell:  $pwsh"
Write-Host ""
Write-Host "Test it now with:  Start-ScheduledTask -TaskName '$TaskName'"
Write-Host "Then check:        Get-ScheduledTaskInfo -TaskName '$TaskName'"
Write-Host "Logs land in:      D:\Vault\Projects\Construction\project-status\.codex\logs\"
