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

    -- coc
    use {'neoclide/coc.nvim', branch = 'release'}
end)
