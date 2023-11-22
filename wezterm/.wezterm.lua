local wezterm = require("wezterm")

return {
	window_background_opacity = 0.95,
  font = wezterm.font({ family = "CaskaydiaCove Nerd Font" }),
  font_size = 13.0,
  line_height = 1.2,
	window_padding = {
		left = 20,
		right = 20,
		top = 20,
		bottom = 20,
	},
  max_fps = 240,
	default_prog = { "pwsh.exe" },
	color_scheme = "OneHalfDark",
	enable_tab_bar = false,
	enable_scroll_bar = false,
}
