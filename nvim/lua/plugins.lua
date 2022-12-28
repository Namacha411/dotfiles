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
	{
		"xiyaowong/nvim-transparent",
		init = function()
			vim.api.nvim_create_autocmd({
				"Colorscheme"
			},{
				command = "TransparentEnable"
			})
		end,
		config = true
	},

	-- lsp
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	{
		"hrsh7th/nvim-cmp",
		config = function()
			local cmp = require('cmp')
			cmp.setup({
				snippet = {
					expand = function(args)
						require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = cmp.mapping.preset.insert({
					['<C-b>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
					['<C-Space>'] = cmp.mapping.complete(),
					['<C-e>'] = cmp.mapping.abort(),
					['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
				}),
				sources = cmp.config.sources({
					{ name = 'nvim_lsp' },
					{ name = 'luasnip' }, -- For luasnip users.
				}, {
					{ name = 'buffer' },
				})
			})
			-- Set configuration for specific filetype.
			cmp.setup.filetype('gitcommit', {
				sources = cmp.config.sources({
					{ name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
				}, {
					{ name = 'buffer' },
				})
			})
			-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline({ '/', '?' }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {{ name = 'buffer' }}
			})
			-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline(':', {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = 'path' }
				}, {
					{ name = 'cmdline' }
				})
			})
		end
	}, {
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require('cmp_nvim_lsp').default_capabilities()
			-- Mappings.
			-- See `:help vim.diagnostic.*` for documentation on any of the below functions
			local opts = { noremap=true, silent=true }
			vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
			vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
			vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
			vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)
			-- Use an on_attach function to only map the following keys
			-- after the language server attaches to the current buffer
			local on_attach = function(client, bufnr)
				-- Enable completion triggered by <c-x><c-o>
				vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
				-- Mappings.
				-- See `:help vim.lsp.*` for documentation on any of the below functions
				local bufopts = { noremap=true, silent=true, buffer=bufnr }
				vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
				vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
				vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
				vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
				vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
				vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
				vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
				vim.keymap.set('n', '<space>wl', function()
				print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end, bufopts)
				vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
				vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
				vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
				vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
				vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
			end
			local lsp_flags = {
				-- This is the default in Nvim 0.7+
				debounce_text_changes = 150,
			}
			require('lspconfig')['pyright'].setup{
				on_attach = on_attach,
				flags = lsp_flags,
				capabilities = capabilities
			}
			require('lspconfig')['rust_analyzer'].setup{
				on_attach = on_attach,
				flags = lsp_flags,
				capabilities = capabilities
			}
		end,
	},
	-- snip
	"L3MON4D3/LuaSnip",
	"saadparwaiz1/cmp_luasnip",

	{
		"nvim-lualine/lualine.nvim",
		config = true
	}, {
		"numToStr/Comment.nvim",
		config = true
	}, {
		"nvim-tree/nvim-tree.lua",
		init = function()
			vim.g.loaded_netrw = 1
			vim.g.loaded_netrwPlugin = 1
		end,
		config = true,
		dependencies = { "nvim-tree/nvim-web-devicons" },
	}, {
		"Pocco81/auto-save.nvim",
		config = true,
	}
})
