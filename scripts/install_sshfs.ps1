<#
.SYNOPSIS
  Install SSHFS-Win for mounting remote filesystems.

.PARAMETER Remove
  Uninstall SSHFS-Win and WinFsp

.EXAMPLE
  .\scripts\install_sshfs.ps1
  .\scripts\install_sshfs.ps1 -Remove
#>
param(
  [switch]$Remove
)

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host "[SSHFS] $m" -ForegroundColor Cyan }
function Ok($m) { Write-Host "[SSHFS] $m" -ForegroundColor Green }

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host "[SSHFS] winget not found" -ForegroundColor Red
  exit 1
}

if ($Remove) {
  Info "Uninstalling SSHFS-Win..."
  winget uninstall SSHFS-Win.SSHFS-Win -e
  winget uninstall WinFsp.WinFsp -e
  Ok "Uninstalled"
  exit 0
}

Info "Installing WinFsp (FUSE for Windows)..."
winget install --id WinFsp.WinFsp -e --accept-source-agreements --accept-package-agreements

Info "Installing SSHFS-Win..."
winget install --id SSHFS-Win.SSHFS-Win -e --accept-source-agreements --accept-package-agreements

Write-Host ""
Ok "SSHFS-Win installed!"
Write-Host ""
Info "Mount a remote filesystem with:"
Write-Host "  net use X: \\sshfs\user@hostname\path" -ForegroundColor Yellow
Write-Host "  .\scripts\mount_devbox.ps1 -DevboxHost your-devbox" -ForegroundColor Yellow
Write-Host ""
