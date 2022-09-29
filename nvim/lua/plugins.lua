-------------------------------------------------
-- 必要のないデフォルトプラグインの無効化
-------------------------------------------------
-- vim.g.did_install_default_menus = 1
-- vim.g.did_install_syntax_menu   = 1
-- vim.g.did_indent_on             = 1
-- vim.g.did_load_filetypes        = 1
-- vim.g.did_load_ftplugin         = 1
--
-- vim.g.loaded_2html_plugin       = 1
-- vim.g.loaded_gzip               = 1
-- vim.g.loaded_man                = 1
-- vim.g.loaded_matchit            = 1
-- vim.g.loaded_matchparen         = 1
-- vim.g.loaded_netrwPlugin        = 1
-- vim.g.loaded_remote_plugins     = 1
-- vim.g.loaded_shada_plugin       = 1
-- vim.g.loaded_spellfile_plugin   = 1
-- vim.g.loaded_tarPlugin          = 1
-- vim.g.loaded_tutor_mode_plugin  = 1
-- vim.g.loaded_zipPlugin          = 1
-- vim.g.skip_loading_mswin        = 1
-------------------------------------------------
-- Packer
-------------------------------------------------
-- This file can be loaded by calling `lua require('plugins')` from your init.vim
-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

local packer = require('packer')

packer.init {
	display = {
		open_fn = require('packer.util').float,
	},
}

packer.startup(function(use)
	-- self
	use {'wbthomason/packer.nvim'}

	-- Colorscheme
	use {'arcticicestudio/nord-vim', opt = true}
	use {'sickill/vim-monokai', opt = true}
	use {'cocopon/iceberg.vim', opt = true}
	use {'navarasu/onedark.nvim', opt = true}
	-- lsp
	use {
		'neovim/nvim-lspconfig',
		config = function()
			require('lspconfig').rust_analyzer.setup({})
		end
	}
	use {
		'j-hui/fidget.nvim',
		config = function()
			require('fidget').setup()
		end,
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
					['<C-b>'] = cmp.mapping.scroll_docs(-1),
					['<C-f>'] = cmp.mapping.scroll_docs(1),
					['<C-Space>'] = cmp.mapping.complete(),
					['<C-e>'] = cmp.mapping.abort(),
					['<CR>'] = cmp.mapping.confirm({ select = true }),
				}),
				sources = cmp.config.sources({
					{ name = 'nvim_lsp' },
					{ name = 'vsnip' },
				}, {
					{ name = 'path' },
					{ name = 'calc' },
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
		end
	}

	-- Other
	use {
		'numToStr/Comment.nvim',
		config = function()
			require('Comment').setup()
		end
	}
	use {
		'akinsho/toggleterm.nvim',
		tag = '*',
		config = function()
			require('toggleterm').setup({})
		end,
		opt = true,
	}
	use {
		'Pocco81/auto-save.nvim',
		config = function()
			require('auto-save').setup({})
		end,
	}
	use { 'ryanoasis/vim-devicons' }
	use {
		'kyazdani42/nvim-tree.lua',
		requires = { 'kyazdani42/nvim-web-devicons' },
		config = function()
			require('nvim-tree').setup()
		end
	}
	use {
		'nvim-lualine/lualine.nvim',
		requires = {
			'kyazdani42/nvim-web-devicons',
			opt = true,
		},
		config = function()
			require('lualine').setup({
				option = { theme = 'iceberg-dark' },
			})
		end
	}

	-- Lnagages
	use {
		'simrat39/rust-tools.nvim',
		config = function()
			require('rust-tools').setup({
				server = {
					settings = {
						['rust-analyzer'] = {
							checkOnSave = { command = 'clippy' },
						},
					}
				}
			})
		end
	}
end)

-- Terminal
local Terminal = require('toggleterm.terminal').Terminal


if vim.fn.has('win32') then
	local pwsh = Terminal:new({ cmd = "pwsh.exe", direction = "float" })

	function Pwsh()
		pwsh:toggle()
	end
end
