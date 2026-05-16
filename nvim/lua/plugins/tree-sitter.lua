return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	event = {
		"BufReadPost",
		"BufNewFile",
	},
	config = function()
		local ts = require("nvim-treesitter")
		ts.install({
			"python",
			"rust",
			"lua",
			"json",
			"yaml",
			"toml",
			"csv",
			"gitignore",
			"html",
			"markdown",
			"markdown_inline",
		})

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				local lang = vim.treesitter.language.get_lang(args.match)
				if not lang then
					return
				end
				local parser = vim.treesitter.get_parser(args.buf, lang)
				if not parser then
					return
				end
				vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				vim.treesitter.start(args.buf, lang)
			end,
		})
	end,
}
