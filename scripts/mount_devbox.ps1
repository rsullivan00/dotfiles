<#
.SYNOPSIS
  Mount Windows devbox filesystem via SSHFS-Win for local editing.

.DESCRIPTION
  Mounts the devbox filesystem through the Dev Tunnel (localhost).
  Requires the tunnel to be running (use devboxterm -TunnelOnly first).

.PARAMETER Unmount
  Unmount the devbox drive

.PARAMETER DriveLetter
  Drive letter to use (default: D)

.PARAMETER Host
  SSH host (default: localhost, assumes tunnel is running)

.PARAMETER Username
  SSH username (default: sshuser)

.PARAMETER KeyFile
  SSH private key file (default: ~/.ssh/id_ed25519_devbox)

.PARAMETER RemotePath
  Remote path to mount (default: C:/Users/username)

.EXAMPLE
  .\scripts\mount_devbox.ps1
  .\scripts\mount_devbox.ps1 -DriveLetter X
  .\scripts\mount_devbox.ps1 -Unmount
#>
param(
  [switch]$Unmount,
  [string]$DriveLetter = "D",
  [string]$Host = "localhost",
  [string]$Username = "sshuser",
  [string]$KeyFile = "$env:USERPROFILE\.ssh\id_ed25519_devbox",
  [string]$RemotePath,
  [string]$TunnelName = "devbox"
)

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host "[Devbox] $m" -ForegroundColor Cyan }
function Ok($m) { Write-Host "[Devbox] $m" -ForegroundColor Green }
function Err($m) { Write-Host "[Devbox] $m" -ForegroundColor Red }

$drive = "${DriveLetter}:"

if ($Unmount) {
  Info "Unmounting $drive..."
  if (Test-Path $drive) {
    net use $drive /delete /y 2>$null
    Ok "Unmounted $drive"
  } else {
    Info "Drive $drive not mounted"
  }
  exit 0
}

# Default remote path to user's home on devbox
if (-not $RemotePath) {
  $RemotePath = "C:/Users/$env:USERNAME"
}

# Check if SSHFS-Win is installed
$sshfsPath = "C:\Program Files\SSHFS-Win\bin\sshfs.exe"
if (-not (Test-Path $sshfsPath)) {
  Err "SSHFS-Win not found. Install with:"
  Write-Host "  winget install WinFsp.WinFsp" -ForegroundColor Yellow
  Write-Host "  winget install SSHFS-Win.SSHFS-Win" -ForegroundColor Yellow
  exit 1
}

# Ensure SSH config has entry for devbox-mount (SSHFS-Win uses ssh config)
$sshDir = "$env:USERPROFILE\.ssh"
if (-not (Test-Path $sshDir)) {
  New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}
$sshConfigPath = "$sshDir\config"
$configHost = "devbox-mount"
$sshConfigEntry = @"

Host $configHost
  HostName $Host
  User $Username
  IdentityFile $KeyFile
  StrictHostKeyChecking no
"@

$configExists = $false
if (Test-Path $sshConfigPath) {
  $existingConfig = Get-Content $sshConfigPath -Raw -ErrorAction SilentlyContinue
  if ($existingConfig -match "Host\s+$configHost") {
    $configExists = $true
  }
}

if (-not $configExists) {
  Info "Adding SSH config entry for $configHost..."
  Add-Content -Path $sshConfigPath -Value $sshConfigEntry
}

# Check if already mounted
if (Test-Path $drive) {
  Info "Drive $drive already in use"
  exit 0
}

# Check if tunnel is running by testing SSH connection
$tunnelRunning = $false
$testConnection = Test-NetConnection -ComputerName localhost -Port 22 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
if ($testConnection.TcpTestSucceeded) {
  $tunnelRunning = $true
}

# Start tunnel if not running
$tunnelJob = $null
if (-not $tunnelRunning) {
  Info "Starting tunnel connection..."

  # Check if logged in to devtunnel
  $loginStatus = devtunnel list 2>&1
  if ($loginStatus -match "not logged in") {
    Info "Please log in to Dev Tunnels:"
    devtunnel login
  }

  # Start tunnel in background
  $tunnelJob = Start-Job -ScriptBlock {
    param($name)
    devtunnel connect $name
  } -ArgumentList $TunnelName

  # Wait for tunnel to establish
  Start-Sleep -Seconds 3

  if ($tunnelJob.State -eq 'Failed') {
    Err "Failed to connect to tunnel"
    Receive-Job $tunnelJob
    Remove-Job $tunnelJob
    exit 1
  }
  Ok "Tunnel connected"
} else {
  Info "Tunnel already running"
}

# SSHFS-Win UNC path format: \\sshfs.k\user@host\path
# Using ssh config alias 'devbox-mount' which specifies the key file
$uncPath = "\\sshfs.k\$Username@$configHost\$RemotePath"
Info "Mounting $uncPath to $drive..."
Info "(Requires tunnel running - use 'devboxterm -TunnelOnly' first)"

net use $drive $uncPath

if ($LASTEXITCODE -eq 0) {
  Ok "Mounted! Edit files at: $drive"
  Write-Host ""
  Info "To unmount: devboxmount -Unmount"
  if ($tunnelJob) {
    Write-Host ""
    Info "Tunnel running in background. Keep this terminal open, or install the tunnel service:"
    Write-Host "  .\scripts\install_devbox_tunnel_service.ps1" -ForegroundColor Yellow
  }
} else {
  Err "Mount failed"
  if ($tunnelJob) {
    Stop-Job $tunnelJob -ErrorAction SilentlyContinue
    Remove-Job $tunnelJob -ErrorAction SilentlyContinue
  }
  exit 1
}
