-- Neovim Configuration
-- Using vim.pack (built-in plugin manager, Neovim 0.12+)

-- Enable Lua module caching for faster startup
vim.loader.enable()

-- Set leader key before anything else
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Load core configuration
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Pre-load plugin globals (must be set before plugins load)
vim.g.copilot_filetypes = { ["*"] = true, markdown = true, yaml = true }
vim.g.tmux_navigator_save_on_switch = 1
vim.g.undotree_SetFocusWhenToggle = 1

-- Build hooks for compiled plugins (must register before vim.pack.add)
vim.api.nvim_create_autocmd("User", {
  pattern = "PackChanged",
  callback = function()
    local pack_dir = vim.fn.stdpath("data") .. "/site/pack/core/opt/"

    local fzf_dir = pack_dir .. "telescope-fzf-native.nvim"
    if vim.fn.isdirectory(fzf_dir) == 1 then
      vim.fn.system({ "make", "-C", fzf_dir })
    end

    local luasnip_dir = pack_dir .. "LuaSnip"
    if vim.fn.isdirectory(luasnip_dir) == 1 then
      vim.fn.system({ "make", "-C", luasnip_dir, "install_jsregexp" })
    end
  end,
})

-- Install and load all plugins
vim.pack.add({
  -- UI
  "https://github.com/projekt0n/github-nvim-theme",
  "https://github.com/nvim-lualine/lualine.nvim",
  "https://github.com/akinsho/bufferline.nvim",
  "https://github.com/lukas-reineke/indent-blankline.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",

  -- Editor
  "https://github.com/github/copilot.vim",
  "https://github.com/mbbill/undotree",
  "https://github.com/christoomey/vim-tmux-navigator",
  "https://github.com/folke/zen-mode.nvim",
  "https://github.com/folke/twilight.nvim",
  "https://github.com/folke/which-key.nvim",
  "https://github.com/windwp/nvim-autopairs",
  "https://github.com/kylechui/nvim-surround",
  "https://github.com/numToStr/Comment.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",

  -- Completion
  "https://github.com/hrsh7th/nvim-cmp",
  "https://github.com/L3MON4D3/LuaSnip",
  "https://github.com/rafamadriz/friendly-snippets",
  "https://github.com/saadparwaiz1/cmp_luasnip",
  "https://github.com/hrsh7th/cmp-nvim-lsp",
  "https://github.com/hrsh7th/cmp-buffer",
  "https://github.com/hrsh7th/cmp-path",
  "https://github.com/hrsh7th/cmp-cmdline",
  "https://github.com/onsails/lspkind.nvim",

  -- LSP
  "https://github.com/williamboman/mason.nvim",
  "https://github.com/williamboman/mason-lspconfig.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/j-hui/fidget.nvim",
  "https://github.com/b0o/schemastore.nvim",

  -- Telescope
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
  "https://github.com/nvim-telescope/telescope-file-browser.nvim",
  "https://github.com/nvim-telescope/telescope-ui-select.nvim",
  "https://github.com/nvim-telescope/telescope-live-grep-args.nvim",

  -- Treesitter
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },

  -- Formatting
  "https://github.com/stevearc/conform.nvim",
})

-- Load plugin configurations (theme first for colorscheme)
require("plugins.ui")
require("plugins.editor")
require("plugins.completion")
require("plugins.lsp")
require("plugins.telescope")
require("plugins.treesitter")
require("plugins.formatting")
