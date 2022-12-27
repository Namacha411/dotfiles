local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--single-branch",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end
vim.opt.runtimepath:prepend(lazypath)

require("lazy").setup({
	-- color scheme
	"folke/tokyonight.nvim",
	"cocopon/iceberg.vim",
	"arcticicestudio/nord-vim",
	"sickill/vim-monokai",
	"navarasu/onedark.nvim",
	"xiyaowong/nvim-transparent",

	"nvim-lualine/lualine.nvim",
	"numToStr/Comment.nvim",
	"nvim-tree/nvim-tree.lua",
})

require("lualine").setup({})

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
require("nvim-tree").setup({})

require("transparent").setup({})
vim.api.nvim_create_autocmd(
	{ "Colorscheme" },
	{ command = "TransparentEnable" }
)

require("Comment").setup({})
