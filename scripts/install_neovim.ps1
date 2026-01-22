<#
.SYNOPSIS
  Install and configure Neovim with LazyVim on Windows.

.PARAMETER Remove
  Remove symlink and optionally restore backup

.PARAMETER SkipInstall
  Skip winget installation (only set up config)

.EXAMPLE
  .\scripts\install_neovim.ps1
  .\scripts\install_neovim.ps1 -SkipInstall
  .\scripts\install_neovim.ps1 -Remove
#>
param(
  [switch]$Remove,
  [switch]$SkipInstall,
  [switch]$SkipElevation
)

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host "[Neovim] $m" -ForegroundColor Cyan }
function Ok($m) { Write-Host "[Neovim] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[Neovim] $m" -ForegroundColor Yellow }
function Err($m) { Write-Host "[Neovim] $m" -ForegroundColor Red }

# Elevation check
if (-not $SkipElevation) {
  $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
  if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Info 'Elevation required for symlinks. Relaunching as Administrator...'
    $scriptPath = $MyInvocation.MyCommand.Path
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$scriptPath`"")
    if ($Remove) { $argList += '-Remove' }
    if ($SkipInstall) { $argList += '-SkipInstall' }
    Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList $argList
    exit 0
  }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$nvimSource = Join-Path $repoRoot 'config\nvim-lazyvim'
$nvimTarget = Join-Path $env:LOCALAPPDATA 'nvim'

function Backup-And-Remove($path) {
  if (Test-Path $path) {
    $item = Get-Item $path -Force
    if ($item.LinkType) {
      Remove-Item $path -Force
      Info "Removed existing symlink: $path"
    }
    else {
      $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
      $backup = "$path.$stamp.bak"
      if ($item.PSIsContainer) {
        Move-Item $path $backup
      }
      else {
        Copy-Item $path $backup
        Remove-Item $path -Force
      }
      Ok "Backed up existing config to: $backup"
    }
  }
}

if ($Remove) {
  Info 'Removing Neovim configuration...'
  if (Test-Path $nvimTarget) {
    $item = Get-Item $nvimTarget -Force
    if ($item.LinkType) {
      Remove-Item $nvimTarget -Force
      Ok 'Removed nvim config symlink'
    }
    else {
      Warn 'Nvim config is not a symlink, not removing'
    }
  }
  else {
    Warn 'No nvim config found'
  }
  exit 0
}

# Install applications
if (-not $SkipInstall) {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Err 'winget not found. Please install App Installer from Microsoft Store.'
    exit 1
  }

  Info 'Installing Neovim...'
  winget install --id Neovim.Neovim -e --accept-source-agreements --accept-package-agreements

  Info 'Installing ripgrep (for telescope)...'
  winget install --id BurntSushi.ripgrep.MSVC -e --accept-source-agreements --accept-package-agreements

  Info 'Installing fd (for telescope)...'
  winget install --id sharkdp.fd -e --accept-source-agreements --accept-package-agreements
}

# Verify source config exists
if (-not (Test-Path $nvimSource)) {
  Err "Neovim config not found: $nvimSource"
  exit 2
}

# Set up Neovim config
Info 'Setting up Neovim config...'
Backup-And-Remove $nvimTarget
New-Item -ItemType Junction -Path $nvimTarget -Target $nvimSource -ErrorAction Stop | Out-Null
Ok "Created link: $nvimTarget -> $nvimSource"

Write-Host ''
Ok 'Neovim setup complete!'
Write-Host ''
Info 'Run "nvim" - LazyVim will auto-install on first launch'
Write-Host ''
