-- Treesitter: Syntax highlighting and folding
-- For Neovim 0.11+ with the new main branch API
-- Note: textobjects temporarily disabled until main branch is stable

return {
  -- Main treesitter plugin (main branch with new API)
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdate", "TSInstall", "TSUninstall" },
    config = function()
      local TS = require("nvim-treesitter")

      -- Install parsers
      local parsers = {
        -- Primary
        "go", "gomod", "gosum", "gowork",
        "typescript", "tsx", "javascript",
        "lua", "luadoc",
        -- Web
        "html", "css", "scss", "json", "jsonc",
        -- Config
        "yaml", "toml", "dockerfile", "terraform", "hcl",
        -- Text
        "markdown", "markdown_inline",
        -- Shell
        "bash", "fish",
        -- Other
        "vim", "vimdoc", "query", "regex", "diff", "gitcommit", "gitignore",
      }

      -- Install missing parsers
      TS.install(parsers)

      -- Enable treesitter-based highlighting via autocommand
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          if ft and ft ~= "" and ft ~= "lazy" then
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
    end,
  },

  -- NOTE: nvim-treesitter-textobjects is temporarily disabled
  -- The main branch API is not yet compatible with lazy.nvim's loading
  -- Text object functionality can be added back once the API stabilizes
  -- For now, use built-in vim text objects (iw, aw, ip, ap, etc.)
}
