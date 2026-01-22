<#
.SYNOPSIS
  Main dotfiles installation script for Windows.

.DESCRIPTION
  Installs development tools and configures dotfiles:
  - Visual Studio 2022
  - VS Code with vim extension
  - Neovim with LazyVim
  - WezTerm terminal
  - SSHFS-Win for remote filesystem mounting
  - VsVim configuration

.PARAMETER SkipVS
  Skip Visual Studio installation

.PARAMETER SkipNeovim
  Skip Neovim installation

.PARAMETER SkipWezTerm
  Skip WezTerm installation

.PARAMETER SkipSSHFS
  Skip SSHFS-Win installation
#>
param(
  [switch]$SkipVS,
  [switch]$SkipNeovim,
  [switch]$SkipWezTerm,
  [switch]$SkipSSHFS
)

$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot

function Info($m) { Write-Host "[Install] $m" -ForegroundColor Cyan }
function Ok($m) { Write-Host "[Install] $m" -ForegroundColor Green }

# Elevation check - elevate once at the start
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Info 'Elevation required. Relaunching as Administrator...'
  $scriptPath = $MyInvocation.MyCommand.Path
  $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$scriptPath`"")
  if ($SkipVS) { $argList += '-SkipVS' }
  if ($SkipNeovim) { $argList += '-SkipNeovim' }
  if ($SkipWezTerm) { $argList += '-SkipWezTerm' }
  if ($SkipSSHFS) { $argList += '-SkipSSHFS' }
  Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList $argList
  exit 0
}

# Check winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host "[Install] winget not found. Please install App Installer from Microsoft Store." -ForegroundColor Red
  exit 1
}

# Visual Studio & VS Code
if (-not $SkipVS) {
  Info 'Installing Visual Studio 2022 Enterprise...'
  winget install --id Microsoft.VisualStudio.2022.Enterprise -e --override "--add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --includeRecommended" --accept-source-agreements --accept-package-agreements

  Info 'Installing VS Code...'
  winget install --id Microsoft.VisualStudioCode -e --accept-source-agreements --accept-package-agreements

  Info 'Installing VS Code vim extension...'
  code --install-extension vscodevim.vim

  # VsVim config (only useful with Visual Studio)
  Info 'Running VsVim setup...'
  & "$scriptDir\scripts\install_vsvimrc.ps1" -SkipElevation
}

# Neovim
if (-not $SkipNeovim) {
  Info 'Running Neovim setup...'
  & "$scriptDir\scripts\install_neovim.ps1" -SkipElevation
}

# WezTerm
if (-not $SkipWezTerm) {
  Info 'Running WezTerm setup...'
  & "$scriptDir\scripts\install_wezterm.ps1" -SkipElevation
}

# SSHFS-Win (for mounting remote filesystems)
if (-not $SkipSSHFS) {
  Info 'Running SSHFS-Win setup...'
  & "$scriptDir\scripts\install_sshfs.ps1"
}

Write-Host ''
Ok '=== All installations complete! ==='
Write-Host ''
