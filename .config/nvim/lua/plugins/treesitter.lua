-- Treesitter: Syntax highlighting and folding

-- Enable treesitter-based highlighting via autocommand
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if ft and ft ~= "" then
      pcall(vim.treesitter.start, args.buf)
    end
  end,
})

-- Enable treesitter-based folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevelstart = 99

-- Incremental selection keymaps
vim.keymap.set("n", "<C-space>", function()
  require("nvim-treesitter.incremental_selection").init_selection()
end, { desc = "Init treesitter selection" })

vim.keymap.set("x", "<C-space>", function()
  require("nvim-treesitter.incremental_selection").node_incremental()
end, { desc = "Increment selection" })

vim.keymap.set("x", "<bs>", function()
  require("nvim-treesitter.incremental_selection").node_decremental()
end, { desc = "Decrement selection" })
