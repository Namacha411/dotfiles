local wezterm = require("wezterm")

local act = wezterm.action

local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- font
config.font = wezterm.font("Fira Code")
config.font_size = 13.0
config.line_height = 1.2
-- window
config.window_background_opacity = 0.95
config.window_padding = {
	left = 20,
	right = 20,
	top = 20,
	bottom = 20,
}
config.max_fps = 240
config.enable_tab_bar = false
config.enable_scroll_bar = false
-- color scheme
config.color_scheme = "One Dark (Gogh)"
-- key config
config.leader = { key = "p", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	{
		key = "h",
		mods = "LEADER",
		action = act.SplitHorizontal({
			domain = "CurrentPaneDomain",
		}),
	},
	{
		key = "v",
		mods = "LEADER",
		action = act.SplitVertical({
			domain = "CurrentPaneDomain",
		}),
	},
	{
		key = "s",
		mods = "LEADER",
		action = act.PaneSelect({}),
	},
	{
		key = "h",
		mods = "LEADER|CTRL",
		action = act.ActivatePaneDirection("Left"),
	},
	{
		key = "l",
		mods = "LEADER|CTRL",
		action = act.ActivatePaneDirection("Right"),
	},
	{
		key = "k",
		mods = "LEADER|CTRL",
		action = act.ActivatePaneDirection("Up"),
	},
	{
		key = "j",
		mods = "LEADER|CTRL",
		action = act.ActivatePaneDirection("Down"),
	},
	{
		key = "c",
		mods = "LEADER",
		action = act.CloseCurrentPane({ confirm = true }),
	},
}

config.default_prog = { "pwsh.exe" }

return config
