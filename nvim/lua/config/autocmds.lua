local function augroup(name)
  return vim.api.nvim_create_augroup("lazy_nvim_" .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("my.lsp", {}),
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    if client and client.server_capabilities.inlayHintProvider then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  pattern = "*",
  callback = function()
    local function get_session_path()
      local session_base = vim.fn.stdpath('cache') .. '/sessions'
      local initial_cwd = vim.fn.getcwd()
      local project_name = initial_cwd:gsub('[/\\:]', '_'):gsub('^_+', '')
      local session_dir = session_base .. '/' .. project_name
      vim.fn.mkdir(session_dir, 'p')
      return session_dir .. '/session.vim'
    end

    local function save()
      local session_path = get_session_path()
      vim.api.nvim_command('mksession! ' .. vim.fn.fnameescape(session_path))
    end

    save()
  end,
})
