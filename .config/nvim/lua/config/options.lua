-- Core Neovim Options

local opt = vim.opt

-- Shell
opt.shell = "/bin/bash"

-- UI
opt.number = true                -- Show line numbers
opt.relativenumber = true        -- Relative line numbers
opt.cursorline = true            -- Highlight current line
opt.showmode = true              -- Show current mode
opt.showcmd = true               -- Show last command
opt.scrolloff = 5                -- Lines to keep above/below cursor
opt.signcolumn = "yes"           -- Always show sign column
opt.termguicolors = true         -- True color support
opt.colorcolumn = "80"           -- Show column at 80 chars
opt.wrap = false                 -- Don't wrap lines

-- Disable visual bell
opt.visualbell = true
opt.errorbells = false

-- Windows
opt.splitright = true            -- Vertical splits to the right
opt.splitbelow = true            -- Horizontal splits below

-- Indentation
opt.autoindent = true            -- Auto indent
opt.smartindent = true           -- Smart indentation
opt.expandtab = true             -- Use spaces instead of tabs
opt.tabstop = 2                  -- Tab = 2 spaces
opt.shiftwidth = 2               -- Indent = 2 spaces
opt.softtabstop = 2              -- Soft tab = 2 spaces

-- Folding (configured in treesitter.lua)
opt.foldenable = true
opt.foldlevel = 99               -- Start with all folds open
opt.foldlevelstart = 99

-- Search
opt.incsearch = true             -- Incremental search
opt.hlsearch = true              -- Highlight search results
opt.ignorecase = true            -- Ignore case when searching
opt.smartcase = true             -- Unless uppercase is used

-- Files
opt.swapfile = false             -- No swap files
opt.backup = false               -- No backup files
opt.undofile = true              -- Persistent undo
opt.undodir = vim.fn.stdpath("data") .. "/undo"

-- Clipboard
opt.clipboard = "unnamedplus"    -- Use system clipboard

-- Mouse
opt.mouse = ""                   -- Disable mouse (enable cmd+c)

-- Completion
opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight = 10               -- Max completion items

-- Performance
opt.updatetime = 250             -- Faster updates
opt.timeoutlen = 300             -- Faster key sequence completion
opt.lazyredraw = false           -- Don't redraw during macros (disabled for noice.nvim compatibility)

-- File encoding
opt.fileencoding = "utf-8"

-- Disable unused built-in plugins
vim.g.loaded_gzip = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_logiPat = 1
vim.g.loaded_rrhelper = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
