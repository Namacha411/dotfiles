return {
	"Pocco81/auto-save.nvim",
	event = "VeryLazy",
	opts = {
		execution_message = {
			message = function() -- message to print on save
				return ("AutoSave: " .. vim.fn.strftime("%H:%M:%S"))
			end,
		},
	},
}
