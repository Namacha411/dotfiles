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

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				local lang = vim.treesitter.language.get_lang(args.match)
				if not lang then
					return
				end
				if not pcall(vim.treesitter.get_parser, args.buf, lang) then
					return
				end
				vim.bo.indentexpr = "v:lua.vim.treesitter.indentexpr()"
			end,
		})
	end,
}
