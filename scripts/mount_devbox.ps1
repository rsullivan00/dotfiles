<#
.SYNOPSIS
  Mount Windows devbox filesystem via SSHFS-Win for local editing.

.PARAMETER Unmount
  Unmount the devbox drive

.PARAMETER DriveLetter
  Drive letter to use (default: D)

.PARAMETER DevboxHost
  Devbox hostname (or set DEVBOX_HOST env var)

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
  [string]$DevboxHost = $env:DEVBOX_HOST,
  [string]$RemotePath
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

# Validate inputs
if (-not $DevboxHost) {
  Err "Devbox hostname required. Set DEVBOX_HOST env var or use -DevboxHost parameter"
  Write-Host "Example: `$env:DEVBOX_HOST = 'mydevbox.devbox.microsoft.com'" -ForegroundColor Yellow
  exit 1
}

# Default remote path to user's home
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

# Check if already mounted
if (Test-Path $drive) {
  Info "Drive $drive already in use"
  exit 0
}

$uncPath = "\\sshfs\$env:USERNAME@$DevboxHost\$RemotePath"
Info "Mounting $uncPath to $drive..."

net use $drive $uncPath

if ($LASTEXITCODE -eq 0) {
  Ok "Mounted! Edit files at: $drive"
  Write-Host ""
  Info "To unmount: .\scripts\mount_devbox.ps1 -Unmount"
} else {
  Err "Mount failed"
  exit 1
}
