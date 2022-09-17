local wezterm = require 'wezterm'

return {
    window_background_image = '$HOME/dotfiles/assets/bg01.jpg',
	window_background_opacity = 0.9,
    window_frame = {
        font = wezterm.font { family = 'CaskaydiaCove Nerd Font' },
        font_size = 13.0,
    },
    window_padding = {
        left = 20,
        right = 20,
        top = 10,
        bottom = 10,
    },
    default_prog = { 'pwsh.exe' },
    color_scheme = 'MaterialOcean',
	enable_tab_bar = false,
	enable_scroll_bar = false,
}
