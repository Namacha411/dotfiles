local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.default_prog = { "pwsh.exe" }
config.use_ime = true

-- tab
config.tab_max_width = 30
wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
  local title = wezterm.truncate_right(string.format(" %-99s", tab.active_pane.title), max_width)
  return {
    { Text = title },
  }
end)

-- font
config.font = wezterm.font("Cascadia Code NF")
config.font_size = 13.0
config.line_height = 1.2

-- cursor
config.animation_fps = 1
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

-- window
config.window_background_opacity = 0.7
config.win32_system_backdrop = "Acrylic"
config.window_decorations = "INTEGRATED_BUTTONS | RESIZE"
config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
}
config.colors = {
  tab_bar = {
    inactive_tab_edge = "none",
  },
}
config.window_padding = {
  left = 15,
  right = 15,
  top = 15,
}
config.max_fps = 240

-- color scheme
config.color_scheme = 'Tokyo Night (Gogh)'

return config
