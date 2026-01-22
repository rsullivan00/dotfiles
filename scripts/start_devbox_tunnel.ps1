<#
.SYNOPSIS
  Start hosting the Dev Tunnel on the devbox.

.PARAMETER TunnelName
  Name of the tunnel (default: devbox)

.EXAMPLE
  .\scripts\start_devbox_tunnel.ps1
#>
param(
  [string]$TunnelName = "devbox"
)

Write-Host "[DevTunnel] Starting tunnel '$TunnelName'..." -ForegroundColor Cyan
Write-Host "[DevTunnel] Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

devtunnel host $TunnelName
