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
  & "$dotfilesRoot\scripts\connect_devbox_tunnel.ps1" @args
}

function devboxmount {
  & "$dotfilesRoot\scripts\mount_devbox.ps1" @args
}

# Alias for quick edit with neovim
Set-Alias -Name vim -Value nvim -ErrorAction SilentlyContinue
