vim.api.nvim_create_user_command("CommaPeriod", function()
  local view = vim.fn.winsaveview()

  vim.cmd([[
    keepjumps keeppatterns %s/、/，/ge
    keepjumps keeppatterns %s/。/．/ge
  ]])

  vim.fn.winrestview(view)
  vim.notify("Normalized: 、→， 。→．", vim.log.levels.INFO)
end, {})

vim.api.nvim_create_user_command("Kutouten", function()
  local view = vim.fn.winsaveview()

  vim.cmd([[
    keepjumps keeppatterns %s/，/、/ge
    keepjumps keeppatterns %s/．/。/ge
  ]])

  vim.fn.winrestview(view)
  vim.notify("Normalized: ，→、 ．→。", vim.log.levels.INFO)
end, {})

