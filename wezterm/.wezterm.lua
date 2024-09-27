local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.default_prog = { "pwsh.exe", "-NoLogo" }
config.use_ime = true

-- tab
config.tab_max_width = 30
wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
  local bg_color = "#393a3d"
  local bg_active_color = "#1e2030"
  local fg_color = "#636da6"
  local fg_active_color = "#c8d3f5"

  local tab_bg_color = bg_color
  local tab_fg_color = fg_color
  if tab.is_active then
    tab_bg_color = bg_active_color
    tab_fg_color = fg_active_color
  end

  local title = wezterm.truncate_right(string.format(" %-99s", tab.active_pane.title), max_width)

  return {
    { Background = { Color = tab_bg_color } },
    { Foreground = { Color = tab_fg_color } },
    { Text = title },
  }
end)

-- font
config.font = wezterm.font("Cascadia Code NF")
config.font_size = 13.0

-- window
config.window_background_opacity = 0.7
config.win32_system_backdrop = "Acrylic"
config.window_decorations = "INTEGRATED_BUTTONS | RESIZE"
config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
}
config.window_background_gradient = {
  colors = { "#39384", "#1d2131", "#131313" },
  blend = "Oklab",
}
config.colors = {
  tab_bar = {
    inactive_tab_edge = "none",
  },
}
config.window_padding = {
  left = 20,
  right = 20,
  top = 20,
}
config.max_fps = 240

-- color scheme
config.color_scheme = 'Tokyo Night (Gogh)'

return config
