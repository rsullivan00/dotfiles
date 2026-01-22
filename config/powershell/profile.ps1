# Dotfiles PowerShell profile
# Source this from your $PROFILE:
#   . C:\src\dotfiles\config\powershell\profile.ps1

# Get the dotfiles root directory
$dotfilesRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $dotfilesRoot) {
  $dotfilesRoot = "C:\src\dotfiles"
}

# Devbox aliases
function devboxterm {
  # Launch in WezTerm if available and not already in WezTerm
  $wezterm = Get-Command wezterm -ErrorAction SilentlyContinue
  $script = "$dotfilesRoot\scripts\connect_devbox_tunnel.ps1"
  if ($wezterm -and -not $env:WEZTERM_PANE) {
    & wezterm start -- powershell -NoExit -File $script
  } else {
    & $script @args
  }
}

function devboxmount {
  & "$dotfilesRoot\scripts\mount_devbox.ps1" @args
}

# Alias for quick edit with neovim
Set-Alias -Name vim -Value nvim -ErrorAction SilentlyContinue
