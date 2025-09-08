<#
 Symlink the repo .vsvimrc into the user profile so Visual Studio (VsVim) picks it up.

 Usage (create link, back up existing file):
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install_vsvimrc.ps1 -Backup

 Remove symlink & optionally restore a backup:
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install_vsvimrc.ps1 -Remove

 Flags:
  -Backup  : back up an existing non-symlink file before replacing (timestamped *.bak)
  -Remove  : remove the symlink; if a backup exists, restore the most recent one
  -Force   : overwrite an existing different symlink without prompt

 Notes:
   - Symbolic links may require elevation unless Developer Mode is enabled
  - Script self-elevates if not already admin
#>
param(
  [switch]$Backup,
  [switch]$Remove,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "[VsVimRC] $m" -ForegroundColor Cyan }
function Ok($m){ Write-Host "[VsVimRC] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[VsVimRC] $m" -ForegroundColor Yellow }
function Err($m){ Write-Host "[VsVimRC] $m" -ForegroundColor Red }

# Elevation check & self-relaunch
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
  Info 'Elevation required for reliable symlink creation. Relaunching as Administrator...'
  $scriptPath = $MyInvocation.MyCommand.Path
  $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$scriptPath`"")
  if($Backup){ $argList += '-Backup' }
  if($Remove){ $argList += '-Remove' }
  if($Force){ $argList += '-Force' }
  Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList $argList | Out-Null
  exit 0
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$repoFile = Join-Path $repoRoot '.vsvimrc'
if(-not (Test-Path $repoFile)){ Err ".vsvimrc not found in repo root ($repoFile)"; exit 2 }

$targetPath = Join-Path $env:USERPROFILE '.vsvimrc'

if($Remove){
  if(Test-Path $targetPath){
    $item = Get-Item $targetPath -Force
    if($item.LinkType){
      Remove-Item $targetPath -Force
      Ok 'Removed symlink'
      # Restore latest backup if present
      $backups = Get-ChildItem -Path ($targetPath + '.*.bak') -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
      if($backups){
        $latest = $backups | Select-Object -First 1
        Copy-Item $latest.FullName $targetPath
        Ok "Restored backup: $($latest.Name)"
      }
    } else {
      Warn 'Existing file is not a symlink; nothing removed'
    }
  } else {
    Warn 'No .vsvimrc present to remove'
  }
  exit 0
}

if(Test-Path $targetPath){
  $item = Get-Item $targetPath -Force
  if($item.LinkType){
    $currTarget = (Get-Item $targetPath).Target | Select-Object -First 1
    if([IO.Path]::GetFullPath($currTarget) -eq [IO.Path]::GetFullPath($repoFile)){
      Info 'Symlink already in place -> OK'
      exit 0
    }
    if($Force){
      Warn 'Replacing existing symlink pointing elsewhere'
      Remove-Item $targetPath -Force
    } else {
      Err 'Different symlink exists. Use -Force to replace.'
      exit 3
    }
  } else {
    if($Backup){
      $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
      $backupFile = "$targetPath.$stamp.bak"
      Copy-Item $targetPath $backupFile -Force
      Ok "Backed up existing file to $(Split-Path $backupFile -Leaf)"
    } else {
      Warn 'Overwriting existing non-symlink file (no backup)'
    }
    Remove-Item $targetPath -Force
  }
}

try {
  New-Item -ItemType SymbolicLink -Path $targetPath -Target $repoFile -ErrorAction Stop | Out-Null
  Ok "Symlink created: $targetPath -> $repoFile"
} catch {
  Err "Failed to create symlink: $($_.Exception.Message)"
  exit 4
}
