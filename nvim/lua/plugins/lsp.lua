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
    config = true,
  },
}
