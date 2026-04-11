-- Telescope: Fuzzy Finder with Extensions

local telescope = require("telescope")
local actions = require("telescope.actions")
local lga_actions = require("telescope-live-grep-args.actions")

telescope.setup({
  defaults = {
    prompt_prefix = " ",
    selection_caret = " ",
    path_display = { "truncate" },
    sorting_strategy = "ascending",
    layout_config = {
      horizontal = {
        prompt_position = "top",
        preview_width = 0.55,
      },
      vertical = {
        mirror = false,
      },
      width = 0.87,
      height = 0.80,
      preview_cutoff = 120,
    },
    mappings = {
      i = {
        ["<C-n>"] = actions.cycle_history_next,
        ["<C-p>"] = actions.cycle_history_prev,
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-c>"] = actions.close,
        ["<CR>"] = actions.select_default,
        ["<C-x>"] = actions.select_horizontal,
        ["<C-v>"] = actions.select_vertical,
        ["<C-t>"] = actions.select_tab,
        ["<C-u>"] = actions.preview_scrolling_up,
        ["<C-d>"] = actions.preview_scrolling_down,
        ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
      },
      n = {
        ["q"] = actions.close,
        ["<CR>"] = actions.select_default,
        ["<C-x>"] = actions.select_horizontal,
        ["<C-v>"] = actions.select_vertical,
        ["<C-t>"] = actions.select_tab,
        ["j"] = actions.move_selection_next,
        ["k"] = actions.move_selection_previous,
        ["gg"] = actions.move_to_top,
        ["G"] = actions.move_to_bottom,
        ["<C-u>"] = actions.preview_scrolling_up,
        ["<C-d>"] = actions.preview_scrolling_down,
      },
    },
    file_ignore_patterns = {
      "node_modules",
      ".git/",
      "%.lock",
      "vendor/",
    },
  },
  pickers = {
    find_files = {
      hidden = true,
      find_command = { "fd", "--type", "f", "--strip-cwd-prefix" },
    },
    live_grep = {
      additional_args = function()
        return { "--hidden" }
      end,
    },
    buffers = {
      show_all_buffers = true,
      sort_lastused = true,
      mappings = {
        i = {
          ["<C-d>"] = actions.delete_buffer,
        },
      },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
    file_browser = {
      hijack_netrw = true,
      hidden = true,
      grouped = true,
    },
    ["ui-select"] = {
      require("telescope.themes").get_dropdown(),
    },
    live_grep_args = {
      auto_quoting = true,
      mappings = {
        i = {
          ["<C-k>"] = lga_actions.quote_prompt(),
          ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
        },
      },
    },
  },
})

-- Load extensions (pcall for fzf in case it's not compiled yet)
pcall(telescope.load_extension, "fzf")
telescope.load_extension("file_browser")
telescope.load_extension("ui-select")
telescope.load_extension("live_grep_args")

-- Keymaps
local map = vim.keymap.set

-- File pickers
map("n", "<C-p>", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Recent files" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
map("n", "<leader>fe", "<cmd>Telescope file_browser<cr>", { desc = "File browser" })

-- Search pickers
map("n", "<leader>sg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
map("n", "<leader>sG", function() telescope.extensions.live_grep_args.live_grep_args() end, { desc = "Live grep (args)" })
map("n", "<leader>sw", "<cmd>Telescope grep_string<cr>", { desc = "Grep word under cursor" })
map("n", "<leader>ss", "<cmd>Telescope current_buffer_fuzzy_find<cr>", { desc = "Search in buffer" })

-- Git pickers
map("n", "<leader>gc", "<cmd>Telescope git_commits<cr>", { desc = "Git commits" })
map("n", "<leader>gs", "<cmd>Telescope git_status<cr>", { desc = "Git status" })
map("n", "<leader>gb", "<cmd>Telescope git_branches<cr>", { desc = "Git branches" })

-- LSP pickers
map("n", "<leader>sd", "<cmd>Telescope diagnostics bufnr=0<cr>", { desc = "Document diagnostics" })
map("n", "<leader>sD", "<cmd>Telescope diagnostics<cr>", { desc = "Workspace diagnostics" })
map("n", "<leader>sr", "<cmd>Telescope lsp_references<cr>", { desc = "References" })
map("n", "<leader>si", "<cmd>Telescope lsp_implementations<cr>", { desc = "Implementations" })
map("n", "<leader>st", "<cmd>Telescope lsp_type_definitions<cr>", { desc = "Type definitions" })

-- Vim pickers
map("n", "<leader>:", "<cmd>Telescope command_history<cr>", { desc = "Command history" })
map("n", "<leader>sh", "<cmd>Telescope help_tags<cr>", { desc = "Help tags" })
map("n", "<leader>sk", "<cmd>Telescope keymaps<cr>", { desc = "Keymaps" })
map("n", "<leader>sm", "<cmd>Telescope marks<cr>", { desc = "Marks" })
map("n", "<leader>sR", "<cmd>Telescope registers<cr>", { desc = "Registers" })
map("n", "<leader>sc", "<cmd>Telescope colorscheme<cr>", { desc = "Colorschemes" })

-- Resume last search
map("n", "<leader><leader>", "<cmd>Telescope resume<cr>", { desc = "Resume last search" })
