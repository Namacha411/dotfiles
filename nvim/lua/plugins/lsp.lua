return {
  {
    "mason-org/mason.nvim",
    build = ":MasonUpdate",
    cmd = { "Mason", "MasonUpdate", "MasonLog", "MasonInstall", "MasonUninstall", "MasonUninstallAll" },
    config = true,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    event = {
      "BufReadPost",
      "BufNewFile",
    },
    dependencies = {
      "neovim/nvim-lspconfig",
    },
    config = function()
      require("mason-lspconfig").setup()

      -- Detect PEP 723 header and return the uv-cached venv Python path for ty LSP.
      -- Requires `uv run --script <file>` to have been run once to create the venv.
      -- See: https://github.com/astral-sh/ty/issues/691
      local function get_pep723_python(bufnr)
        local filepath = vim.api.nvim_buf_get_name(bufnr)
        if filepath == "" then return nil end

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 20, false)
        for _, line in ipairs(lines) do
          if line:match("^# /// script") then
            local result = vim.fn.system({ "uv", "python", "find", "--script", filepath })
            if vim.v.shell_error ~= 0 then return nil end
            return vim.trim(result)
          end
        end
        return nil
      end

      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*.py",
        callback = function(ev)
          local python_path = get_pep723_python(ev.buf)
          if not python_path then return end

          -- Use vim.lsp.start() directly so lspconfig server registration is not required
          -- and each buffer gets its own client with the correct venv python path.
          vim.lsp.start({
            name = "ty",
            cmd = { "ty", "server" },
            init_options = {
              environment = { python = python_path },
            },
            root_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ev.buf), ":h"),
          }, { bufnr = ev.buf })
        end,
      })
    end,
  },
}
