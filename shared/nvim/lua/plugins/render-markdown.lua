return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  opts = {
    latex = { enabled = false },
    completions = { blink = { enabled = true } },
    anti_conceal = { enabled = false },
    -- anti_concealをOFFにしたため、フェンス行(```)が完全な空行に見えてしまう。
    -- 境界線バーを表示して位置がわかるようにする。
    code = { border = "thin" },
    -- HTMLコメントも同じ理由で行ごと消えるため、常に生テキストのまま表示する。
    html = { comment = { conceal = false } },
  },
}
