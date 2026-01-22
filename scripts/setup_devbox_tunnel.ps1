<#
.SYNOPSIS
  One-time setup for Dev Tunnel on a devbox. Run this on the devbox.

.DESCRIPTION
  - Installs OpenSSH Server (requires admin)
  - Creates local 'sshuser' account for SSH (domain accounts don't work with sshd as SYSTEM)
  - Installs Dev Tunnels CLI
  - Creates a persistent tunnel with SSH port

.PARAMETER TunnelName
  Name for the tunnel (default: devbox)

.PARAMETER SshUserPassword
  Password for the local sshuser account (will prompt if not provided)

.PARAMETER PublicKeyPath
  Path to public key to authorize (default: prompts for manual entry)

.EXAMPLE
  .\scripts\setup_devbox_tunnel.ps1
  .\scripts\setup_devbox_tunnel.ps1 -TunnelName mydevbox
#>
param(
  [string]$TunnelName = "devbox",
  [string]$SshUserPassword,
  [string]$PublicKeyPath
)

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host "[DevboxSetup] $m" -ForegroundColor Cyan }
function Ok($m) { Write-Host "[DevboxSetup] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[DevboxSetup] $m" -ForegroundColor Yellow }
function Err($m) { Write-Host "[DevboxSetup] $m" -ForegroundColor Red }

# Auto-elevate
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Info "Elevation required. Relaunching as Administrator..."
  $scriptPath = $MyInvocation.MyCommand.Path
  $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$scriptPath`"", "-TunnelName", $TunnelName)
  if ($SshUserPassword) { $argList += @("-SshUserPassword", $SshUserPassword) }
  if ($PublicKeyPath) { $argList += @("-PublicKeyPath", $PublicKeyPath) }
  Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList $argList -Wait
  exit 0
}

# Install OpenSSH Server
Info "Checking OpenSSH Server..."
$sshCapability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

if ($sshCapability.State -ne 'Installed') {
  Info "Installing OpenSSH Server..."
  Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
}

# Start and enable SSH service
Info "Configuring SSH service..."
Start-Service sshd -ErrorAction SilentlyContinue
Set-Service sshd -StartupType Automatic
Ok "SSH service started and set to auto-start"

# Create local sshuser account (domain accounts don't work with sshd running as SYSTEM)
Info "Setting up local SSH user account..."
$sshUserExists = Get-LocalUser -Name "sshuser" -ErrorAction SilentlyContinue
if (-not $sshUserExists) {
  if (-not $SshUserPassword) {
    $securePassword = Read-Host -Prompt "Enter password for new 'sshuser' account" -AsSecureString
  } else {
    $securePassword = ConvertTo-SecureString $SshUserPassword -AsPlainText -Force
  }
  New-LocalUser -Name "sshuser" -Password $securePassword -Description "SSH access user for Dev Tunnel"
  Add-LocalGroupMember -Group "Administrators" -Member "sshuser"
  Ok "Created local 'sshuser' account"
} else {
  Warn "Local 'sshuser' account already exists"
}

# Set up SSH key authentication
Info "Setting up SSH key authentication..."
$authKeysFile = "C:\ProgramData\ssh\administrators_authorized_keys"

if ($PublicKeyPath -and (Test-Path $PublicKeyPath)) {
  $pubKey = Get-Content $PublicKeyPath
} else {
  Write-Host ""
  Write-Host "Paste your SSH public key (from client's ~/.ssh/id_ed25519_devbox.pub):" -ForegroundColor Yellow
  $pubKey = Read-Host
}

if ($pubKey) {
  # Add key if not already present
  $existingKeys = ""
  if (Test-Path $authKeysFile) {
    $existingKeys = Get-Content $authKeysFile -Raw -ErrorAction SilentlyContinue
  }
  if ($existingKeys -and $existingKeys.Contains($pubKey)) {
    Warn "Public key already authorized"
  } else {
    Add-Content -Path $authKeysFile -Value $pubKey
    Ok "Public key added to authorized_keys"
  }

  # Fix permissions on administrators_authorized_keys
  icacls $authKeysFile /inheritance:r | Out-Null
  icacls $authKeysFile /grant "SYSTEM:F" | Out-Null
  icacls $authKeysFile /grant "Administrators:F" | Out-Null
  Ok "Set permissions on administrators_authorized_keys"
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
Info "On your CLIENT machine:"
Write-Host "  1. Generate SSH key: ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_devbox" -ForegroundColor Yellow
Write-Host "  2. Copy public key to devbox (already done if you pasted it above)" -ForegroundColor Yellow
Write-Host "  3. Connect: .\scripts\connect_devbox_tunnel.ps1" -ForegroundColor Yellow
Write-Host ""
