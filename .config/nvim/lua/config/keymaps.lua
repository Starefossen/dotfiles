-- Keymaps Configuration

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Escape with jj
map("i", "jj", "<Esc>", opts)

-- Disable arrow keys
map({ "n", "i" }, "<Up>", "<Nop>", opts)
map({ "n", "i" }, "<Down>", "<Nop>", opts)
map({ "n", "i" }, "<Left>", "<Nop>", opts)
map({ "n", "i" }, "<Right>", "<Nop>", opts)

-- Better up/down movement (visual lines)
map("n", "j", "gj", opts)
map("n", "k", "gk", opts)

-- Move to beginning/end of line
map("n", "B", "^", opts)
map("n", "E", "$", opts)

-- Disable default $/^
map("n", "$", "<Nop>", opts)
map("n", "^", "<Nop>", opts)

-- Clear search highlight
map("n", "<leader><Space>", ":nohlsearch<CR>", { noremap = true, silent = true, desc = "Clear search highlight" })

-- Save file
map("n", "<F1>", ":w<CR>", { noremap = true, desc = "Save file" })

-- Toggle paste mode
map("n", "<F2>", ":set invpaste paste?<CR>", { noremap = true, desc = "Toggle paste mode" })

-- Folding with space
map("n", "<Space>", "za", { noremap = true, desc = "Toggle fold" })

-- Edit and source config
map("n", "<leader>ev", ":vsplit $MYVIMRC<CR>", { noremap = true, desc = "Edit config" })
map("n", "<leader>sv", ":source $MYVIMRC<CR>", { noremap = true, desc = "Source config" })

-- Tab navigation
map("n", "<leader>n", "gt", { noremap = true, silent = true, desc = "Next tab" })
map("n", "<leader>p", "gT", { noremap = true, silent = true, desc = "Previous tab" })

-- Paragraph formatting
map("n", "<leader>f", "gqip", { noremap = true, silent = true, desc = "Format paragraph" })

-- Window navigation (better with vim-tmux-navigator)
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- Resize windows with arrows
map("n", "<C-Up>", ":resize -2<CR>", opts)
map("n", "<C-Down>", ":resize +2<CR>", opts)
map("n", "<C-Left>", ":vertical resize -2<CR>", opts)
map("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Buffer navigation
map("n", "<S-l>", ":bnext<CR>", opts)
map("n", "<S-h>", ":bprevious<CR>", opts)
map("n", "<leader>bd", ":bdelete<CR>", { noremap = true, desc = "Delete buffer" })

-- Stay in visual mode when indenting
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- Move text up and down in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Keep cursor centered when scrolling
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)

-- Diagnostic keymaps
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic message" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic list" })

-- Lazy.nvim
map("n", "<leader>l", ":Lazy<CR>", { noremap = true, desc = "Open Lazy" })
