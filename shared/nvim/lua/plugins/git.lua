return {
	"lewis6991/gitsigns.nvim",
	event = {
		"BufReadPost",
		"BufNewFile",
		"BufWritePre",
	},
	main = "gitsigns",
	opts = {
		signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
		numhl = true, -- Toggle with `:Gitsigns toggle_numhl`
		current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
		current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
	},
}
