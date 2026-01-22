<#
.SYNOPSIS
  Set up PowerShell profile with dotfiles aliases.

.DESCRIPTION
  Adds a line to your PowerShell profile to source the dotfiles profile,
  which includes aliases like 'devboxterm' and 'devboxmount'.

.PARAMETER Remove
  Remove the dotfiles line from your profile

.EXAMPLE
  .\scripts\install_powershell_profile.ps1
  .\scripts\install_powershell_profile.ps1 -Remove
#>
param(
  [switch]$Remove
)

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host "[Profile] $m" -ForegroundColor Cyan }
function Ok($m) { Write-Host "[Profile] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[Profile] $m" -ForegroundColor Yellow }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$dotfilesProfile = Join-Path $repoRoot 'config\powershell\profile.ps1'
$sourceLine = ". `"$dotfilesProfile`""

# Ensure profile directory exists
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
  New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Ensure profile file exists
if (-not (Test-Path $PROFILE)) {
  New-Item -ItemType File -Path $PROFILE -Force | Out-Null
  Info "Created profile: $PROFILE"
}

$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if (-not $profileContent) { $profileContent = "" }

if ($Remove) {
  if ($profileContent -match [regex]::Escape($dotfilesProfile)) {
    $newContent = ($profileContent -split "`n" | Where-Object { $_ -notmatch [regex]::Escape($dotfilesProfile) }) -join "`n"
    Set-Content $PROFILE -Value $newContent.TrimEnd()
    Ok "Removed dotfiles from profile"
  } else {
    Warn "Dotfiles not found in profile"
  }
  exit 0
}

if ($profileContent -match [regex]::Escape($dotfilesProfile)) {
  Info "Dotfiles already in profile"
} else {
  Add-Content $PROFILE -Value "`n# Dotfiles`n$sourceLine"
  Ok "Added dotfiles to profile: $PROFILE"
}

Write-Host ""
Ok "Profile configured!"
Info "Restart PowerShell or run:"
Write-Host "  . `$PROFILE" -ForegroundColor Yellow
Write-Host ""
Info "Available aliases:"
Write-Host "  devboxterm   - Connect to devbox via tunnel + SSH" -ForegroundColor Yellow
Write-Host "  devboxmount  - Mount devbox via SSHFS" -ForegroundColor Yellow
Write-Host "  vim          - Alias for nvim" -ForegroundColor Yellow
Write-Host ""
