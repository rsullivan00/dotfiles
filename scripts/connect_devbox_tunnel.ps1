<#
.SYNOPSIS
  Connect to a devbox tunnel and open SSH session.

.DESCRIPTION
  Starts the tunnel connection in the background, then opens SSH.
  When you exit SSH, the tunnel connection closes.

.PARAMETER TunnelName
  Name of the tunnel (default: devbox)

.PARAMETER Username
  SSH username (default: current user)

.PARAMETER TunnelOnly
  Only connect tunnel, don't open SSH

.EXAMPLE
  .\scripts\connect_devbox_tunnel.ps1
  .\scripts\connect_devbox_tunnel.ps1 -Username ricksullivan
#>
param(
  [string]$TunnelName = "devbox",
  [string]$Username = $env:USERNAME,
  [switch]$TunnelOnly
)

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host "[DevTunnel] $m" -ForegroundColor Cyan }
function Ok($m) { Write-Host "[DevTunnel] $m" -ForegroundColor Green }
function Err($m) { Write-Host "[DevTunnel] $m" -ForegroundColor Red }

# Check if logged in
$loginStatus = devtunnel list 2>&1
if ($loginStatus -match "not logged in") {
  Info "Please log in to Dev Tunnels:"
  devtunnel login
}

Info "Starting tunnel connection..."

# Start tunnel in background
$tunnelJob = Start-Job -ScriptBlock {
  param($name)
  devtunnel connect $name
} -ArgumentList $TunnelName

# Wait for tunnel to establish
Start-Sleep -Seconds 2

# Check if tunnel started
if ($tunnelJob.State -eq 'Failed') {
  Err "Failed to connect to tunnel"
  Receive-Job $tunnelJob
  Remove-Job $tunnelJob
  exit 1
}

Ok "Tunnel connected"

if ($TunnelOnly) {
  Info "Tunnel running in background. Press Ctrl+C to disconnect."
  Info "SSH command: ssh $Username@localhost"
  try {
    Wait-Job $tunnelJob
  } finally {
    Stop-Job $tunnelJob -ErrorAction SilentlyContinue
    Remove-Job $tunnelJob -ErrorAction SilentlyContinue
  }
} else {
  Info "Opening SSH session..."
  Write-Host ""

  try {
    # SSH to localhost (tunnel forwards to devbox)
    ssh "$Username@localhost"
  } finally {
    # Clean up tunnel when SSH exits
    Info "Closing tunnel..."
    Stop-Job $tunnelJob -ErrorAction SilentlyContinue
    Remove-Job $tunnelJob -ErrorAction SilentlyContinue
    Ok "Disconnected"
  }
}
