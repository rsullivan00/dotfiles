<#
.SYNOPSIS
  Install the Claude Code config + native Rust statusline binary.

.DESCRIPTION
  1. Ensures rustup/cargo is installed (installs via winget if missing).
  2. Builds the statusline Rust crate at .claude/statusline in release mode.
  3. Copies the built binary to $HOME\.claude\statusline.exe.
  4. Symlinks .claude\settings.json into $HOME\.claude\
     (falls back to copy if symlink creation is not permitted).

  Settings.json references the binary via $HOME/.claude/statusline.exe.
  Claude Code runs statusline commands through bash on Windows, so $HOME
  (not %USERPROFILE%) is the right variable to use.

.PARAMETER Remove
  Remove the installed binary and symlinked settings.json (does not uninstall rustup).
#>
param(
  [switch]$Remove
)

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host "[Claude] $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "[Claude] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[Claude] $m" -ForegroundColor Yellow }

function New-SymlinkOrCopy($src, $dst) {
  try {
    New-Item -ItemType SymbolicLink -Path $dst -Target $src -Force | Out-Null
    Ok "Linked: $dst -> $src"
  } catch {
    Warn "Symlink failed (need Admin or Developer Mode). Falling back to copy: $dst"
    Copy-Item -Path $src -Destination $dst -Force
  }
}

$repoRoot  = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$srcDir    = Join-Path $repoRoot '.claude'
$crateDir  = Join-Path $srcDir 'statusline'
$targetDir = Join-Path $env:USERPROFILE '.claude'
$binTarget = Join-Path $targetDir 'statusline.exe'
$settingsSrc    = Join-Path $srcDir 'settings.json'
$settingsTarget = Join-Path $targetDir 'settings.json'

if (-not (Test-Path $targetDir)) {
  Info "Creating $targetDir"
  New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

# --- Remove path ---
if ($Remove) {
  foreach ($p in @($settingsTarget, $binTarget)) {
    if (Test-Path $p) {
      Remove-Item $p -Force
      Ok "Removed: $p"
    }
  }
  exit 0
}

# --- Ensure cargo is installed ---
$cargoBin = Join-Path $env:USERPROFILE '.cargo\bin'
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
  if (Test-Path (Join-Path $cargoBin 'cargo.exe')) {
    Info "Adding $cargoBin to PATH for this session"
    $env:PATH = "$cargoBin;$env:PATH"
  } else {
    Info 'cargo not found — installing rustup via winget...'
    winget install --id Rustlang.Rustup -e --accept-source-agreements --accept-package-agreements
    $env:PATH = "$cargoBin;$env:PATH"
    if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
      throw 'cargo still not on PATH after rustup install; open a new shell and rerun.'
    }
    rustup default stable
  }
}

# --- Build the statusline crate ---
Info 'Building statusline (cargo build --release)...'
Push-Location $crateDir
try {
  cargo build --release
  if ($LASTEXITCODE -ne 0) { throw 'cargo build failed' }
} finally {
  Pop-Location
}

$builtBin = Join-Path $crateDir 'target\release\statusline.exe'
if (-not (Test-Path $builtBin)) {
  throw "Expected binary not found: $builtBin"
}

Info "Installing binary -> $binTarget"
Copy-Item -Path $builtBin -Destination $binTarget -Force
Ok "Installed: $binTarget"

# --- Link settings.json ---
if (Test-Path $settingsTarget) {
  $item = Get-Item $settingsTarget -Force
  if ($item.LinkType -eq 'SymbolicLink' -and $item.Target -eq $settingsSrc) {
    Info 'settings.json already linked'
  } else {
    $backup = "$settingsTarget.bak"
    Warn "Backing up existing settings.json to $backup"
    Move-Item -Path $settingsTarget -Destination $backup -Force
    New-SymlinkOrCopy $settingsSrc $settingsTarget
  }
} else {
  New-SymlinkOrCopy $settingsSrc $settingsTarget
}

Write-Host ''
Ok 'Claude Code install complete.'
