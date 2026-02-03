local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

-- ============================================================================
-- Shell & Input
-- ============================================================================
config.default_prog = { "pwsh.exe" }
config.use_ime = true

-- ============================================================================
-- Font Configuration
-- ============================================================================
config.font = wezterm.font("Cascadia Code NF")
config.font_size = 13.0
config.line_height = 1.2

-- ============================================================================
-- Cursor Settings
-- ============================================================================
config.animation_fps = 1
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

-- ============================================================================
-- Tab Bar Configuration
-- ============================================================================
config.tab_max_width = 30

wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
  local title = wezterm.truncate_right(string.format(" %-99s", tab.active_pane.title), max_width)
  return {
    { Text = title },
  }
end)

-- ============================================================================
-- Window Appearance
-- ============================================================================
-- Background & Transparency
config.window_background_opacity = 0.6
config.win32_system_backdrop = "Acrylic"

-- Window Decorations
config.window_decorations = "RESIZE"
config.window_frame = {
  inactive_titlebar_bg = "None",
  active_titlebar_bg = "None",
}

-- Padding
config.window_padding = {
  left = 15,
  right = 15,
  top = 15,
}

-- ============================================================================
-- Color Scheme
-- ============================================================================
config.color_scheme = 'Tokyo Night (Gogh)'
config.colors = {
  tab_bar = {
    inactive_tab_edge = "None",
  },
}

-- ============================================================================
-- Performance Settings
-- ============================================================================
config.max_fps = 120
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

-- ============================================================================
-- Key Bindings
-- ============================================================================
config.disable_default_key_bindings = true

config.keys = {
  -- Tab Navigation
  { key = 'Tab', mods = 'CTRL',       action = act.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'SHIFT|CTRL', action = act.ActivateTabRelative(-1) },
  { key = 't',   mods = 'SHIFT|CTRL', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w',   mods = 'SHIFT|CTRL', action = act.CloseCurrentTab { confirm = true } },

  -- Font Size Control
  { key = '+',   mods = 'SHIFT|CTRL', action = act.IncreaseFontSize },
  { key = '=',   mods = 'SHIFT|CTRL', action = act.DecreaseFontSize },

  -- Clipboard Operations
  { key = 'c',   mods = 'SHIFT|CTRL', action = act.CopyTo 'Clipboard' },
  { key = 'v',   mods = 'SHIFT|CTRL', action = act.PasteFrom 'Clipboard' },

  -- Other Commands
  { key = 'p',   mods = 'SHIFT|CTRL', action = act.ActivateCommandPalette },
  { key = 'r',   mods = 'SHIFT|CTRL', action = act.ReloadConfiguration },
}

return config
