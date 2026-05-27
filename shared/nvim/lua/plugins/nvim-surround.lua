return {
  "kylechui/nvim-surround",
  version = "*", -- Use for stability; omit to use `main` branch for the latest features
  main = "nvim-surround",
  event = {
    "BufReadPost",
    "BufNewFile",
    "BufWritePre",
  },
  opts = {},
}
