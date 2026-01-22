<#
.SYNOPSIS
  Install the Dev Tunnel as a Windows scheduled task that runs at login.

.DESCRIPTION
  Creates a scheduled task that automatically starts the tunnel
  when you log in to the devbox.

.PARAMETER TunnelName
  Name of the tunnel (default: devbox)

.PARAMETER Remove
  Remove the scheduled task

.EXAMPLE
  .\scripts\install_devbox_tunnel_service.ps1
  .\scripts\install_devbox_tunnel_service.ps1 -Remove
#>
param(
  [string]$TunnelName = "devbox",
  [switch]$Remove
)

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host "[DevTunnel] $m" -ForegroundColor Cyan }
function Ok($m) { Write-Host "[DevTunnel] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[DevTunnel] $m" -ForegroundColor Yellow }
function Err($m) { Write-Host "[DevTunnel] $m" -ForegroundColor Red }

$taskName = "DevTunnel-$TunnelName"

if ($Remove) {
  Info "Removing scheduled task '$taskName'..."
  Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
  Ok "Scheduled task removed"
  exit 0
}

# Find devtunnel path
$devtunnelPath = (Get-Command devtunnel -ErrorAction SilentlyContinue).Source
if (-not $devtunnelPath) {
  Err "devtunnel not found. Run install_devtunnel.ps1 first."
  exit 1
}

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
  Warn "Task '$taskName' already exists. Removing and recreating..."
  Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

Info "Creating scheduled task '$taskName'..."

# Create action - run devtunnel host
$action = New-ScheduledTaskAction -Execute $devtunnelPath -Argument "host $TunnelName"

# Trigger at logon for current user
$trigger = New-ScheduledTaskTrigger -AtLogon -User $env:USERNAME

# Settings - allow running on battery, don't stop if on battery, restart on failure
$settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -RestartCount 3 `
  -RestartInterval (New-TimeSpan -Minutes 1) `
  -ExecutionTimeLimit (New-TimeSpan -Days 365)

# Register the task
Register-ScheduledTask `
  -TaskName $taskName `
  -Action $action `
  -Trigger $trigger `
  -Settings $settings `
  -Description "Host Dev Tunnel '$TunnelName' for remote SSH access" `
  -RunLevel Highest

Ok "Scheduled task created!"
Write-Host ""
Info "The tunnel will start automatically when you log in."
Info "To start it now:"
Write-Host "  Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor Yellow
Write-Host ""
Info "To check status:"
Write-Host "  Get-ScheduledTask -TaskName '$taskName' | Get-ScheduledTaskInfo" -ForegroundColor Yellow
Write-Host ""
Info "To remove:"
Write-Host "  .\scripts\install_devbox_tunnel_service.ps1 -Remove" -ForegroundColor Yellow
Write-Host ""
