" editor settings ==================================
set noswapfile
set nobackup
set autoread

set number
set relativenumber
set cursorline
set incsearch

set clipboard+=unnamed

set list
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%,space:_
set tabstop=4
set shiftwidth=4
set expandtab

set fenc=utf8
set encoding=utf8

syntax enable
filetype plugin indent on

" vim-plug =================================================
call plug#begin(stdpath('data') . '/plugged')
    " color scheme
    Plug 'cocopon/iceberg.vim', {'do': 'cp colors/* ./colors/' }
    Plug 'sickill/vim-monokai', {'do': 'cp colors/* ./colors/' }
    Plug 'guns/xterm-color-table.vim'

    " airline
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'

    " file tree
    Plug 'preservim/nerdtree'

    " vim icons
    Plug 'ryanoasis/vim-devicons'

    " autosave
     Plug 'Pocco81/AutoSave.nvim'
call plug#end()

" Plugins settings ==========================================
" Airline
let g:airline_theme='raven'

" nerd tree
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>

" auto commands
augroup TransparentBG
  	autocmd!
	autocmd Colorscheme * highlight Normal ctermbg=none
	autocmd Colorscheme * highlight NonText ctermbg=none
	autocmd Colorscheme * highlight LineNr ctermbg=none
	autocmd Colorscheme * highlight Folded ctermbg=none
	autocmd Colorscheme * highlight EndOfBuffer ctermbg=none 
augroup END

" color scheme
set background=dark
colorscheme monokai

" Lua script ====================================
lua << EOF
-- autosave
local autosave = require("autosave")
autosave.setup(
    {
        enabled = true,
        execution_message = "AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"),
        events = {"InsertLeave", "TextChanged"},
        conditions = {
            exists = true,
            filename_is_not = {},
            filetype_is_not = {},
            modifiable = true
        },
        write_all_buffers = false,
        on_off_commands = true,
        clean_command_line_interval = 0,
        debounce_delay = 135
    }
)
EOF
