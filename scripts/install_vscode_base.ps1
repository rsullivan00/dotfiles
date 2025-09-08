<#
 Symlink VS Code user-level settings & keybindings to this repo's .vscode versions.
 Elevation required to guarantee symbolic link creation.

 Usage:
   Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File "./scripts/install_vscode_base.ps1" -Backup'

 Flags:
  -Backup  : back up existing non-symlink user files (timestamped)
  -Remove  : remove the symlinks and restore the most recent backup if present

 Behavior:
   - Only real symbolic links are created (no hard link / copy fallback)
   - Fails fast if a symlink can't be created
  - Per-workspace .vscode/ settings still override user settings

 Notes:
  - Even though Developer Mode can allow non-admin symlinks, admin is enforced for determinism
   - Extension recommendations remain workspace-scoped
   - Elevation is verified by checking the current security principal
#>
param(
  [switch]$Backup,
  [switch]$Remove
)

# Elevation check
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
  Write-Host '[VSCodeDotfiles] Elevation required. Relaunching with Administrator privileges...' -ForegroundColor Yellow
  $scriptPath = $MyInvocation.MyCommand.Path
  $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$scriptPath`"")
  if($Backup){ $argList += '-Backup' }
  if($Remove){ $argList += '-Remove' }
  try {
    Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList $argList
  } catch {
    Write-Host "[VSCodeDotfiles] ERROR: Failed to trigger elevation: $($_.Exception.Message)" -ForegroundColor Red
    exit 2
  }
  exit 0
}

$ErrorActionPreference = 'Stop'

function Write-Info($msg){ Write-Host "[VSCodeDotfiles] $msg" -ForegroundColor Cyan }
function Write-Warn($msg){ Write-Host "[VSCodeDotfiles] $msg" -ForegroundColor Yellow }
function Write-Ok($msg){ Write-Host "[VSCodeDotfiles] $msg" -ForegroundColor Green }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$dotVscode = Join-Path $repoRoot '.vscode'
$userVscode = Join-Path $env:APPDATA 'Code\User'

if (-not (Test-Path $dotVscode)) { throw ".vscode folder not found in repo root: $dotVscode" }
if (-not (Test-Path $userVscode)) { New-Item -ItemType Directory -Path $userVscode | Out-Null }

$targets = @('settings.json','keybindings.json')
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

foreach($name in $targets){
  $src = Join-Path $dotVscode $name
  if(-not (Test-Path $src)){ Write-Warn "Skipping $name (not present in repo)"; continue }
  $dst = Join-Path $userVscode $name

  if($Remove){
    if((Test-Path $dst) -and (Get-Item $dst).LinkType){
      Remove-Item $dst -Force
      Write-Ok "Removed symlink $dst"
      $backup = "$dst.backup"
      if(Test-Path $backup){
        Move-Item $backup $dst -Force
        Write-Ok "Restored backup for $name"
      }
    } else {
      Write-Warn "$name not a symlink; nothing to remove"
    }
    continue
  }

  if(Test-Path $dst){
    $isLink = $null -ne (Get-Item $dst).LinkType
    if($isLink){
      $currentTarget = (Get-Item $dst).Target
      if([IO.Path]::GetFullPath($currentTarget) -eq [IO.Path]::GetFullPath($src)){
        Write-Info "$name already linked -> OK"; continue
      }
      Write-Warn "$name is a symlink to different target; replacing"
      Remove-Item $dst -Force
    } else {
      if($Backup.IsPresent){
        $backupFile = "$dst.$timestamp.bak"
        Copy-Item $dst $backupFile -Force
        Write-Ok "Backed up existing $name to $(Split-Path $backupFile -Leaf)"
      } else {
        Write-Warn "Existing $name will be overwritten (no backup)"
      }
      Remove-Item $dst -Force
    }
  }

  try {
    New-Item -ItemType SymbolicLink -Path $dst -Target $src -ErrorAction Stop | Out-Null
    Write-Ok "Symlink created for $name"
  } catch {
    Write-Host "[VSCodeDotfiles] FATAL: Failed to create symlink for $name -> $($_.Exception.Message)" -ForegroundColor Red
    exit 3
  }
}

if($Remove){ Write-Ok 'Removal complete.' } else { Write-Ok 'Setup complete.' }
