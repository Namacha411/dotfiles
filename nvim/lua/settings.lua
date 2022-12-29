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
vim.opt.smarttab = ture
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.showtabline = 2

-- 文字コード
vim.opt.fenc = [[utf8]]
vim.opt.encoding = [[utf8]]

-- クリップボード
vim.opt.clipboard = "unnamed,unnamedplus"

-- マウス操作
vim.opt.mouse = 'a'

-- キー設定
vim.keymap.set('n', 'j', 'gj')
vim.keymap.set('n', 'k', 'gk')
vim.keymap.set('n', '<ESC>', ':nohlsearch<CR>')

