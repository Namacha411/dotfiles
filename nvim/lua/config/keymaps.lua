local map = vim.keymap.set

-- better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })

map("n", "<ESC>", ":nohlsearch<CR>", { desc = "検索のハイライトをクリア", remap = true })

map("t", "<C-\\>", "<C-\\><C-N>", { desc = "ターミナルモードからノーマルモードに戻る", remap = true })

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
map('n', '<leader>e', vim.diagnostic.open_float, { desc = "診断情報をフロートウィンドウで表示" })
map('n', '[d', vim.diagnostic.goto_prev, { desc = "前の診断へ移動" })
map('n', ']d', vim.diagnostic.goto_next, { desc = "次の診断へ移動" })
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = "診断をロケーションリストに設定" })

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local buf = ev.buf
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = "宣言へ移動", buffer = buf })
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = "定義へ移動", buffer = buf })
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = "ホバー情報を表示", buffer = buf })
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = "実装へ移動", buffer = buf })
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, { desc = "シグネチャヘルプを表示", buffer = buf })
    vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, { desc = "ワークスペースフォルダを追加", buffer = buf })
    vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, { desc = "ワークスペースフォルダを削除", buffer = buf })
    vim.keymap.set('n', '<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, { desc = "現在のLSPセッションに登録されているワークスペースフォルダを表示", buffer = buf })
    vim.keymap.set('n', '<leader>cD', vim.lsp.buf.type_definition, { desc = "型定義へ移動", buffer = buf })
    vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, { desc = "シンボルの名前を変更", buffer = buf })
    vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, { desc = "コードアクション", buffer = buf })
    vim.keymap.set('n', '<leader>cf', function()
      vim.lsp.buf.format { async = true }
    end, { desc = "バッファをフォーマット", buffer = buf })
  end,
})

-- fzf-lua builtin action
map('n', '<leader>ff', function() require('fzf-lua').files() end, { desc = "ファイル検索" })
map('n', '<leader>fg', function() require('fzf-lua').live_grep() end, { desc = "テキスト検索" })
map('n', '<leader>fb', function() require('fzf-lua').buffers() end, { desc = "バッファ一覧" })
map('n', '<leader>fh', function() require('fzf-lua').helptags() end, { desc = "ヘルプタグ検索" })
map('n', '<leader>fo', function() require('fzf-lua').treesitter() end, { desc = "アウトライン表示" })
map('n', '<leader>fd', function() require('fzf-lua').diagnostics_document() end, { desc = "診断情報の検索" })
map('n', '<leader>fm', function() require('fzf-lua').marks() end, { desc = "マークの検索" })
map('n', '<leader>fc', function() require('fzf-lua').commands() end, { desc = "コマンドの検索" })

map('n', '<leader>o', ":Oil<CR>", { desc = "ファイルエクスプローラー" })

vim.keymap.set("n", "<leader>s", function()
  local function get_session_path()
    local session_base = vim.fn.stdpath('cache') .. '/sessions'
    local initial_cwd = vim.fn.getcwd()
    local project_name = initial_cwd:gsub('[/\\:]', '_'):gsub('^_+', '')
    local session_dir = session_base .. '/' .. project_name
    vim.fn.mkdir(session_dir, 'p')
    return session_dir .. '/session.vim'
  end

  local session_path = get_session_path()
  if vim.fn.filereadable(session_path) == 1 then
    vim.cmd('%bdelete')
    vim.cmd('silent! source ' .. vim.fn.fnameescape(session_path))
  else
    vim.notify('No Session found: ' .. session_path, vim.log.levels.WARN)
  end
end, { noremap = true, desc = "セッションの復帰" })
