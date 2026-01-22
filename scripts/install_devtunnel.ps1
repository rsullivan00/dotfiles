<#
.SYNOPSIS
  Install Microsoft Dev Tunnels CLI.

.EXAMPLE
  .\scripts\install_devtunnel.ps1
#>

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host "[DevTunnel] $m" -ForegroundColor Cyan }
function Ok($m) { Write-Host "[DevTunnel] $m" -ForegroundColor Green }

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host "[DevTunnel] winget not found" -ForegroundColor Red
  exit 1
}

Info "Installing Microsoft Dev Tunnels CLI..."
winget install --id Microsoft.devtunnel -e --accept-source-agreements --accept-package-agreements

Write-Host ""
Ok "Dev Tunnels CLI installed!"
Write-Host ""
Info "Next steps:"
Write-Host "  1. Run: devtunnel login"
Write-Host "  2. On devbox: .\scripts\setup_devbox_tunnel.ps1"
Write-Host "  3. On local:  .\scripts\connect_devbox_tunnel.ps1"
Write-Host ""
