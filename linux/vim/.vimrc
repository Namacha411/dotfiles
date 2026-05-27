vim9script
#--------------------------------------
# 基本設定
#--------------------------------------
# 文字コード設定
scriptencoding utf-8
set fenc=utf-8
set encoding=utf-8
set fileformats=unix,dos,mac
set ambiwidth=double

# 検索設定
set smartcase
set incsearch
set hlsearch
set wrapscan

# クリップボード
set clipboard+=unnamed
set clipboard+=unnamedplus

# 読み込みファイル設定
set noswapfile
set nobackup
set autoread
set hidden
set ttyfast

#--------------------------------------
# 表示設定
#--------------------------------------
# シンタックスハイライト
syntax on
set showmatch
set background=dark
colorscheme darkblue

# 行関係
set number
set relativenumber
set display=lastline
set sidescroll=1

# ステータス
set showcmd
set showmode
set ruler
set title

# 補完
set wildmenu
set wildmode=list:longest,full
set wildoptions=fuzzy,pum,tagfile
set history=10000

# 不可視文字の表示
set list
set listchars=tab:»∙,trail:∙,eol:↵,extends:»,precedes:«,nbsp:%,space:∙

# インデント
set autoindent
set smarttab
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab


#--------------------------------------
# ステータスライン
#--------------------------------------
set laststatus=2

def SetStatusLineColor()
    var m = mode()
    if m == "i"
        highlight statusline ctermbg=2
    elseif m == "v" || m == "V"
        highlight statusline ctermbg=5
    elseif m == "n"
        highlight statusline ctermbg=1
    endif
enddef

highlight statusline ctermbg=1
augroup StatusLineColor
    autocmd!
    autocmd ModeChanged * SetStatusLineColor()
augroup END

# 左
set statusline=
set statusline+=%m
set statusline+=%f
# 右
set statusline+=%=
set statusline+=[Ln%l:Col%c\(%p%%)]
set statusline+=[%{&fileencoding}]
set statusline+=[%{&fileformat}]
set statusline+=%y


#--------------------------------------
# キー設定
#--------------------------------------
set backspace=indent,eol,start
set mouse=a

nnoremap j gj
nnoremap k gk
nnoremap <ESC> :nohlsearch<CR>

