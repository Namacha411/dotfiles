return {
	"stevearc/aerial.nvim",
	lazy = true,
	config = function()
		require("aerial").setup({
			backends = { "treesitter" },
		})
	end,
}
