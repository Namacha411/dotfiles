"--------------------------------------
" 基本設定
"--------------------------------------
" 読み込みファイル設定
set noswapfile
set nobackup
set autoread
set hidden
set ttyfast

" 検索設定
set smartcase
set incsearch
set hlsearch
set wrapscan

" クリップボード
set clipboard+=unnamed
set clipboard+=unnamedplus

" 文字コード設定
set fenc=utf8
set encoding=utf8
set fileformat=unix
set ambiwidth=double
scriptencoding utf8


"--------------------------------------
" 表示設定
"--------------------------------------
" シンタックスハイライト
syntax on
set showmatch
set background=dark
colorscheme darkblue

" 行関係
set number
set relativenumber
" set cursorline

" ステータスライン
set laststatus=2
set showcmd
set showmode
set ruler
set title

" 補完
set wildmenu
set wildmode=list:longest,full
set history=10000

" 不可視文字の表示
set list
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%,space:_

" インデント
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab


"--------------------------------------
" キーバインド
"--------------------------------------
nnoremap j gj
nnoremap k gk
nnoremap <ESC> :nohlsearch<CR>
set backspace=indent,eol,start
set mouse=a
