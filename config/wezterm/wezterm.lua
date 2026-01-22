-- WezTerm configuration
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Performance / rendering
config.front_end = "WebGpu" -- GPU-accelerated rendering
config.animation_fps = 60
config.max_fps = 120

-- Appearance
config.color_scheme = "Tokyo Night"
config.font = wezterm.font("JetBrains Mono", { weight = "Medium" })
config.font_size = 11.0
config.line_height = 1.1

-- Window
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}
config.window_decorations = "RESIZE"
config.initial_cols = 120
config.initial_rows = 35

-- Tab bar
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- Cursor
config.default_cursor_style = "SteadyBlock"

-- Bell
config.audible_bell = "Disabled"
config.visual_bell = {
  fade_in_duration_ms = 75,
  fade_out_duration_ms = 75,
  target = "CursorColor",
}

-- Shell - use PowerShell by default on Windows
if wezterm.target_triple:find("windows") then
  config.default_prog = { "pwsh.exe", "-NoLogo" }
end

-- SSH Domains (for devbox connections via tunnel)
-- Requires tunnel to be running: devboxterm -TunnelOnly or the scheduled service
config.ssh_domains = {
  {
    name = "devbox",
    remote_address = "localhost",
    username = "sshuser",
    ssh_option = {
      identityfile = wezterm.home_dir .. "/.ssh/id_ed25519_devbox",
    },
  },
}

-- Keybindings
config.keys = {
  -- Ctrl+Shift+P for command palette (like VS Code)
  { key = "p", mods = "CTRL|SHIFT", action = wezterm.action.ActivateCommandPalette },
  -- Quick split panes
  { key = "|", mods = "CTRL|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "_", mods = "CTRL|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
  -- Connect to devbox (Ctrl+Shift+D)
  { key = "d", mods = "CTRL|SHIFT", action = wezterm.action.SpawnTab({ DomainName = "devbox" }) },
}

return config
