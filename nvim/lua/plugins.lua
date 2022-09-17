-- This file can be loaded by calling `lua require('plugins')` from your init.vim
-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

local packer = require('packer')

return packer.startup(function(use)
	-- self
	use {'wbthomason/packer.nvim'}

	-- Colorscheme
	use {'arcticicestudio/nord-vim', opt = true}
	use {'sickill/vim-monokai', opt = true}
	use {'cocopon/iceberg.vim', opt = true}

	-- icons
	use {'ryanoasis/vim-devicons'}

	-- file tree
	use {
		'kyazdani42/nvim-tree.lua',
		requires = {
			'kyazdani42/nvim-web-devicons',
		},
		config = function()
			require('nvim-tree').setup()
		end
	}

	-- autosave
	use {
		'Pocco81/auto-save.nvim',
		config = function()
			require('auto-save').setup({
				enabled = true,
				execution_message = {
					message = function() -- message to print on save
						return ("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"))
					end,
					dim = 0.18, -- dim the color of `message`
					cleaning_interval = 1250, -- (milliseconds) automatically clean MsgArea after displaying `message`. See :h MsgArea
				},
				trigger_events = {"InsertLeave", "TextChanged"}, -- vim events that trigger auto-save. See :h events
				condition = function(buf)
					local fn = vim.fn
					local utils = require("auto-save.utils.data")

					if
						fn.getbufvar(buf, "&modifiable") == 1 and
						utils.not_in(fn.getbufvar(buf, "&filetype"), {}) then
						return true -- met condition(s), can save
					end
					return false -- can't save
				end,
				write_all_buffers = false, -- write all buffers when the current one meets `condition`
				debounce_delay = 135, -- saves the file at most every `debounce_delay` milliseconds
				callbacks = { -- functions to be executed at different intervals
					enabling = nil, -- ran when enabling auto-save
					disabling = nil, -- ran when disabling auto-save
					before_asserting_save = nil, -- ran before checking `condition`
					before_saving = nil, -- ran before doing the actual save
					after_saving = nil -- ran after doing the actual save
				}
			})
		end
	}

	-- airline
	use {
		'vim-airline/vim-airline',
		requires = {'vim-airline/vim-airline-themes'},
		setup = function()
			vim.g.airline_theme = 'raven'
		end
	}

	-- lsp
	use {'neovim/nvim-lspconfig'}
	use {
		'williamboman/mason.nvim',
		config = function()
			require('mason').setup()
		end
	}
	use {
		'williamboman/mason-lspconfig.nvim',
		config = function()
			require('mason-lspconfig').setup({function(server)
				local opt = {
					capabilities = require('cmp_nvim_lsp').update_capabilities(
						vim.lsp.protocol.make_client_capabilities()
					)
				}
				require('lspconfig')[server].setup(opt)
			end})
		end
	}

	-- snippet
	use {'hrsh7th/cmp-vsnip'}
	use {'hrsh7th/vim-vsnip'}

	-- cmp
	use {'hrsh7th/cmp-nvim-lsp'}
	use {'hrsh7th/cmp-buffer'}
	use {'hrsh7th/cmp-path'}
	use {'hrsh7th/cmp-cmdline'}
	use {
		'hrsh7th/nvim-cmp',
		config = function()
			local cmp = require('cmp')
			cmp.setup({
				snippet = {
					expand = function(args)
						vim.fn["vsnip#anonymous"](args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = cmp.mapping.preset.insert({
					['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item(), {'i', 'c'}),
					['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item(), {'i', 'c'}),
					['<C-b>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
					['<C-Space>'] = cmp.mapping.complete(),
					['<C-e>'] = cmp.mapping.abort(),
					['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
				}),
				sources = cmp.config.sources({
					{ name = 'nvim_lsp' },
					{ name = 'vsnip' },
				}, {
					{ name = 'buffer' },
				})
			})
			-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline('/', {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {{ name = 'buffer' }}
			})
			-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline(':', {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources(
					{{ name = 'path' }},
					{{ name = 'cmdline' }}
				)
			})

			-- setup lspconfig
			local capabilities = require('cmp_nvim_lsp').update_capabilities(
				vim.lsp.protocol.make_client_capabilities()
			)
			local lsp = require('lspconfig')
			lsp.rust_analyzer.setup {
				capabilities = capabilities
			}
		end
	}

	use {
		'simrat39/rust-tools.nvim',
		config = function()
			require('rust-tools').setup({
				server = {
					settings = {
						['rust-analyzer'] = {
							checkOnSave = {
								command = 'clippy'
							},
						},
					}
				},
			})
		end
	}
end)
