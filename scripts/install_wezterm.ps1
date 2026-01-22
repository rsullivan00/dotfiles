<#
.SYNOPSIS
  Install and configure WezTerm on Windows.

.PARAMETER Remove
  Remove symlink and optionally restore backup

.PARAMETER SkipInstall
  Skip winget installation (only set up config)

.EXAMPLE
  .\scripts\install_wezterm.ps1
  .\scripts\install_wezterm.ps1 -SkipInstall
  .\scripts\install_wezterm.ps1 -Remove
#>
param(
  [switch]$Remove,
  [switch]$SkipInstall,
  [switch]$SkipElevation
)

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host "[WezTerm] $m" -ForegroundColor Cyan }
function Ok($m) { Write-Host "[WezTerm] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[WezTerm] $m" -ForegroundColor Yellow }
function Err($m) { Write-Host "[WezTerm] $m" -ForegroundColor Red }

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
$weztermSource = Join-Path $repoRoot 'config\wezterm\wezterm.lua'
$weztermTarget = Join-Path $env:USERPROFILE '.wezterm.lua'

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
      Copy-Item $path $backup
      Remove-Item $path -Force
      Ok "Backed up existing config to: $backup"
    }
  }
}

if ($Remove) {
  Info 'Removing WezTerm configuration...'
  if (Test-Path $weztermTarget) {
    $item = Get-Item $weztermTarget -Force
    if ($item.LinkType) {
      Remove-Item $weztermTarget -Force
      Ok 'Removed wezterm config symlink'
    }
    else {
      Warn 'WezTerm config is not a symlink, not removing'
    }
  }
  else {
    Warn 'No wezterm config found'
  }
  exit 0
}

# Install WezTerm
if (-not $SkipInstall) {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Err 'winget not found. Please install App Installer from Microsoft Store.'
    exit 1
  }

  Info 'Installing WezTerm...'
  winget install --id wez.wezterm -e --accept-source-agreements --accept-package-agreements
}

# Verify source config exists
if (-not (Test-Path $weztermSource)) {
  Err "WezTerm config not found: $weztermSource"
  exit 2
}

# Set up WezTerm config
Info 'Setting up WezTerm config...'
Backup-And-Remove $weztermTarget
New-Item -ItemType SymbolicLink -Path $weztermTarget -Target $weztermSource -ErrorAction Stop | Out-Null
Ok "Created link: $weztermTarget -> $weztermSource"

Write-Host ''
Ok 'WezTerm setup complete!'
Write-Host ''
