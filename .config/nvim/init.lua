-- Neovim Configuration
-- Migrated to Lua with lazy.nvim package manager

-- Set leader key before lazy.nvim
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load core configuration
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Setup lazy.nvim with plugin specs
require("lazy").setup("plugins", {
  defaults = {
    lazy = false,
  },
  install = {
    colorscheme = { "github_dark_dimmed" },
  },
  checker = {
    enabled = false, -- Disable automatic checking for updates
    notify = false,
  },
  change_detection = {
    enabled = false, -- Disable change detection to prevent unnecessary reloads
    notify = false,
  },
  performance = {
    cache = {
      enabled = true, -- Enable caching
    },
    reset_packpath = true,
    rtp = {
      reset = true,
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- Explicitly set lockfile location
  git = {
    timeout = 300, -- Increase timeout to avoid partial downloads
  },
})
