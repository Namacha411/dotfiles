return {
	"romus204/tree-sitter-manager.nvim",
	lazy = false,
	config = function()
		-- python, lua, markdown, markdown_inline は Neovim 0.12 にバンドル済みのため除外
		require("tree-sitter-manager").setup({
			ensure_installed = {
				"rust",
				"json",
				"yaml",
				"toml",
				"csv",
				"gitignore",
				"html",
			},
    })
	end,
}
