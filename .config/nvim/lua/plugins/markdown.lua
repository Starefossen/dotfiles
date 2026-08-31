-- Markdown rendering (render-markdown.nvim)
pcall(function()
  require("render-markdown").setup({
    heading = {
      sign = true,
      icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
    },
    code = {
      sign = true,
      width = "block",
      right_pad = 1,
    },
    bullet = {
      icons = { "●", "○", "◆", "◇" },
    },
    checkbox = {
      unchecked = { icon = "󰄱" },
      checked = { icon = "󰱒" },
      custom = {
        todo = { raw = "[-]", rendered = "󰥔" },
      },
    },
  })
end)

-- Enable code block highlighting for native vim markdown
vim.g.markdown_fenced_languages = {
  "html",
  "python",
  "lua",
  "vim",
  "go",
  "bash",
  "json",
  "yaml",
  "sql",
  "javascript",
  "typescript",
}
