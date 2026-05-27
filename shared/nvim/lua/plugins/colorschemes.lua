return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    style = "moon",       -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
    light_style = "day",  -- The theme is used when the background is set to light
    transparent = true,   -- Enable this to disable setting the background color
    terminal_colors = true, -- Configure the colors used when opening a `:terminal` in [Neovim](https://github.com/neovim/neovim)
  },
}
