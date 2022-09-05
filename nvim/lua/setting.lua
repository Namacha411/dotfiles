-------------------------------------------------
-- auto command
-------------------------------------------------
-- 背景の透明化
local TransparentBG = vim.api.nvim_create_augroup("TransparentBG", {
    clear = true
})
vim.api.nvim_create_autocmd({"Colorscheme"}, {
    command = "highlight Normal ctermbg = none",
    group = TransparentBG
})
vim.api.nvim_create_autocmd({"Colorscheme"}, {
    command = "highlight NonText ctermbg = none",
    group = TransparentBG
})
vim.api.nvim_create_autocmd({"Colorscheme"}, {
    command = "highlight LineNr ctermbg = none",
    group = TransparentBG
})
vim.api.nvim_create_autocmd({"Colorscheme"}, {
    command = "highlight Folded ctermbg = none",
    group = TransparentBG
})
vim.api.nvim_create_autocmd({"Colorscheme"}, {
    command = "highlight EndOfBuffer ctermbg = none",
    group = TransparentBG
})

-------------------------------------------------
-- オプション
-------------------------------------------------
-- ファイル読み込み関係
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.autoread = true

-- 表示関係
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.incsearch = true
vim.opt.list = true
vim.opt.listchars = {
    tab = [[»·]],
    trail = [[·]],
    eol = [[↲]],
    extends = [[»]],
    precedes = [[«]],
    nbsp = [[%]],
    space = [[·]]
}
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = ture
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.background = 'dark'

vim.cmd([[syntax enable]])
vim.cmd([[filetype plugin indent on]])
vim.cmd([[colorscheme monokai]])

-- 文字コード
vim.opt.fenc = [[utf8]]
vim.opt.encoding = [[utf8]]

-- クリップボード
vim.opt.clipboard:append({
    unnamed = true
})

-- マウス操作
vim.opt.mouse = 'a'

-- terminal
if vim.fn.has('win32') then
    vim.opt.shell = 'pwsh'
end
vim.cmd([[tnoremap <Esc> <C-\><C-n>]])
vim.cmd([[command! -nargs=* T split | wincmd j | resize 15 | terminal <args>]])
vim.api.nvim_create_autocmd({"TermOpen"}, {
    command = "startinsert"
})
