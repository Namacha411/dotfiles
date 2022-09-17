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
end)
