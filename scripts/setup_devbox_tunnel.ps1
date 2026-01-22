<#
.SYNOPSIS
  One-time setup for Dev Tunnel on a devbox. Run this on the devbox.

.DESCRIPTION
  - Installs OpenSSH Server (requires admin)
  - Installs Dev Tunnels CLI
  - Creates a persistent tunnel with SSH port

.PARAMETER TunnelName
  Name for the tunnel (default: devbox)

.EXAMPLE
  .\scripts\setup_devbox_tunnel.ps1
  .\scripts\setup_devbox_tunnel.ps1 -TunnelName mydevbox
#>
param(
  [string]$TunnelName = "devbox"
)

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host "[DevboxSetup] $m" -ForegroundColor Cyan }
function Ok($m) { Write-Host "[DevboxSetup] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[DevboxSetup] $m" -ForegroundColor Yellow }
function Err($m) { Write-Host "[DevboxSetup] $m" -ForegroundColor Red }

# Check if running as admin
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Install OpenSSH Server
Info "Checking OpenSSH Server..."
$sshCapability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

if ($sshCapability.State -ne 'Installed') {
  if (-not $isAdmin) {
    Err "OpenSSH Server not installed. Please run this script as Administrator."
    exit 1
  }
  Info "Installing OpenSSH Server..."
  Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
}

# Start and enable SSH service
Info "Configuring SSH service..."
if ($isAdmin) {
  Start-Service sshd -ErrorAction SilentlyContinue
  Set-Service sshd -StartupType Automatic
  Ok "SSH service started and set to auto-start"
} else {
  $sshStatus = Get-Service sshd -ErrorAction SilentlyContinue
  if ($sshStatus -and $sshStatus.Status -eq 'Running') {
    Ok "SSH service is running"
  } else {
    Warn "SSH service not running. Start it manually or re-run as Administrator."
  }
}

# Install devtunnel CLI
if (-not (Get-Command devtunnel -ErrorAction SilentlyContinue)) {
  Info "Installing Dev Tunnels CLI..."
  winget install --id Microsoft.devtunnel -e --accept-source-agreements --accept-package-agreements

  # Refresh PATH
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Login to devtunnel
Info "Checking devtunnel login..."
$loginStatus = devtunnel list 2>&1
if ($loginStatus -match "not logged in") {
  Info "Please log in to Dev Tunnels:"
  devtunnel login
}

# Create tunnel
Info "Creating tunnel '$TunnelName'..."
$existingTunnel = devtunnel show $TunnelName 2>&1
if ($existingTunnel -match "Tunnel ID") {
  Warn "Tunnel '$TunnelName' already exists"
} else {
  devtunnel create $TunnelName
  Ok "Tunnel created"
}

# Add SSH port
Info "Adding SSH port to tunnel..."
$portList = devtunnel port list $TunnelName 2>&1
if ($portList -match ":22") {
  Warn "Port 22 already configured"
} else {
  devtunnel port create $TunnelName -p 22
  Ok "Port 22 added"
}

Write-Host ""
Ok "=== Devbox tunnel setup complete! ==="
Write-Host ""
Info "To start the tunnel:"
Write-Host "  .\scripts\start_devbox_tunnel.ps1" -ForegroundColor Yellow
Write-Host ""
Info "To install as a service (auto-start):"
Write-Host "  .\scripts\install_devbox_tunnel_service.ps1" -ForegroundColor Yellow
Write-Host ""
