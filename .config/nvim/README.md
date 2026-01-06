# Neovim Configuration

Modern Neovim 0.11+ configuration using Lua and lazy.nvim package manager.

## Prerequisites

- **Neovim** 0.11+ (required for native LSP API)
- **Git** for plugin management
- **Node.js** for GitHub Copilot and some LSP servers
- **ripgrep** for Telescope live grep: `brew install ripgrep`
- **fd** for Telescope file finding: `brew install fd`
- **A Nerd Font** for icons (e.g., JetBrainsMono Nerd Font)

## Installation

1. Backup existing config (if any):

```bash
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
```

2. Clone/copy this config to `~/.config/nvim`

3. Start Neovim — plugins will auto-install on first launch:

```bash
nvim
```

4. Install language servers via Mason:

```vim
:Mason
```

## Structure

```
~/.config/nvim/
├── init.lua                 # Entry point, lazy.nvim bootstrap
├── lua/
│   ├── config/
│   │   ├── options.lua      # Core Neovim settings
│   │   ├── keymaps.lua      # Key bindings
│   │   └── autocmds.lua     # Autocommands
│   └── plugins/
│       ├── ui.lua           # Theme, statusline, bufferline
│       ├── editor.lua       # Copilot, undotree, zen-mode, etc.
│       ├── telescope.lua    # Fuzzy finder
│       ├── lsp.lua          # Native LSP configuration (0.11+)
│       ├── completion.lua   # Autocompletion
│       ├── formatting.lua   # Code formatting
│       └── treesitter.lua   # Syntax highlighting
└── README.md
```

## Key Bindings

**Leader key:** `,`

### General

| Key       | Action                     |
| --------- | -------------------------- |
| `jj`      | Exit insert mode           |
| `<Space>` | Toggle fold                |
| `<F1>`    | Save file                  |
| `<F2>`    | Toggle paste mode          |
| `,ev`     | Edit config                |
| `,sv`     | Source config              |
| `,l`      | Open Lazy (plugin manager) |
| `,?`      | Show buffer local keymaps  |

### Navigation

| Key               | Action                              |
| ----------------- | ----------------------------------- |
| `B` / `E`         | Beginning / End of line             |
| `j` / `k`         | Move by visual lines                |
| `<C-h/j/k/l>`     | Navigate windows/tmux panes         |
| `<S-h>` / `<S-l>` | Previous / Next buffer              |
| `[b` / `]b`       | Previous / Next buffer (bufferline) |

### Telescope (Fuzzy Finder)

| Key         | Action                 |
| ----------- | ---------------------- |
| `<C-p>`     | Find files             |
| `,ff`       | Find files             |
| `,fr`       | Recent files           |
| `,fb`       | Buffers                |
| `,fe`       | File browser           |
| `,sg`       | Live grep              |
| `,sG`       | Live grep with args    |
| `,sw`       | Grep word under cursor |
| `,ss`       | Search in buffer       |
| `,sh`       | Help tags              |
| `,sk`       | Keymaps                |
| `,gc`       | Git commits            |
| `,gs`       | Git status             |
| `,gb`       | Git branches           |
| `,<leader>` | Resume last search     |

**Inside Telescope:**

| Key       | Action                |
| --------- | --------------------- |
| `<C-j/k>` | Navigate results      |
| `<C-x>`   | Open horizontal split |
| `<C-v>`   | Open vertical split   |
| `<C-t>`   | Open in new tab       |
| `<Tab>`   | Toggle selection      |
| `<C-q>`   | Send to quickfix      |

### LSP (Language Server)

| Key         | Action                     |
| ----------- | -------------------------- |
| `gd`        | Go to definition           |
| `gD`        | Go to declaration          |
| `gi`        | Go to implementation       |
| `gr`        | Go to references           |
| `gt`        | Go to type definition      |
| `K`         | Hover documentation        |
| `<C-k>`     | Signature help             |
| `,ca`       | Code action                |
| `,cr`       | Rename symbol              |
| `,th`       | Toggle inlay hints         |
| `[d` / `]d` | Previous / Next diagnostic |
| `,e`        | Show diagnostic float      |
| `,q`        | Open diagnostic list       |

### Formatting

| Key              | Action                 |
| ---------------- | ---------------------- |
| `,cf`            | Format buffer          |
| `:FormatDisable` | Disable format on save |
| `:FormatEnable`  | Enable format on save  |

### Completion (nvim-cmp)

| Key         | Action                   |
| ----------- | ------------------------ |
| `<C-Space>` | Trigger completion       |
| `<C-j/k>`   | Navigate items           |
| `<Tab>`     | Confirm / Expand snippet |
| `<S-Tab>`   | Jump backward in snippet |
| `<C-e>`     | Abort completion         |
| `<CR>`      | Confirm selection        |

### Git (gitsigns)

| Key         | Action               |
| ----------- | -------------------- |
| `]h` / `[h` | Next / Previous hunk |
| `,ghs`      | Stage hunk           |
| `,ghr`      | Reset hunk           |
| `,ghS`      | Stage buffer         |
| `,ghu`      | Undo stage hunk      |
| `,ghp`      | Preview hunk         |
| `,ghb`      | Blame line           |
| `,ghd`      | Diff this            |

### Editor

| Key           | Action              |
| ------------- | ------------------- |
| `,u`          | Toggle Undotree     |
| `,z`          | Toggle Zen Mode     |
| `,n` / `,p`   | Next / Previous tab |
| `gcc`         | Toggle line comment |
| `gc` (visual) | Toggle comment      |

### Treesitter

| Key             | Action                   |
| --------------- | ------------------------ |
| `<C-space>`     | Init/Increment selection |
| `<BS>` (visual) | Decrement selection      |

### Buffer Management

| Key   | Action                     |
| ----- | -------------------------- |
| `,bp` | Toggle pin buffer          |
| `,bo` | Close other buffers        |
| `,br` | Close buffers to the right |
| `,bl` | Close buffers to the left  |
| `,bd` | Delete buffer              |

## Plugins

### UI

- **github-nvim-theme** — GitHub's dark dimmed theme
- **lualine.nvim** — Statusline
- **bufferline.nvim** — Tab/buffer bar
- **indent-blankline.nvim** — Indent guides

### Editor

- **copilot.vim** — GitHub Copilot
- **undotree** — Undo history visualizer
- **vim-tmux-navigator** — Seamless tmux/vim navigation
- **zen-mode.nvim** — Distraction-free writing
- **twilight.nvim** — Dim inactive code
- **which-key.nvim** — Keybinding hints
- **nvim-autopairs** — Auto-close brackets
- **nvim-surround** — Surround text objects
- **Comment.nvim** — Easy commenting
- **gitsigns.nvim** — Git integration

### Telescope

- **telescope.nvim** — Fuzzy finder
- **telescope-fzf-native.nvim** — FZF sorter (fast)
- **telescope-file-browser.nvim** — File browser
- **telescope-ui-select.nvim** — Pretty vim.ui.select
- **telescope-live-grep-args.nvim** — Grep with arguments

### LSP & Completion

- **nvim-lspconfig** — LSP quickstart configs (uses native 0.11+ API)
- **mason.nvim** — LSP/tool installer
- **mason-lspconfig.nvim** — Mason + lspconfig bridge
- **nvim-cmp** — Autocompletion
- **LuaSnip** — Snippet engine
- **friendly-snippets** — Snippet collection
- **fidget.nvim** — LSP progress indicator
- **schemastore.nvim** — JSON/YAML schemas

### Formatting

- **conform.nvim** — Format on save with goimports, prettier, etc.

### Syntax

- **nvim-treesitter** — Syntax highlighting (main branch, 0.11+ API)

## Language Servers

Pre-configured and auto-installed via Mason:

| Language              | Server   |
| --------------------- | -------- |
| Go                    | gopls    |
| TypeScript/JavaScript | ts_ls    |
| Lua                   | lua_ls   |
| JSON                  | jsonls   |
| YAML                  | yamlls   |
| HTML                  | html     |
| CSS                   | cssls    |
| Bash                  | bashls   |
| Docker                | dockerls |

## Formatters

Configured in conform.nvim:

| Language                    | Formatter        |
| --------------------------- | ---------------- |
| Go                          | goimports, gofmt |
| TypeScript/JavaScript       | prettier         |
| HTML/CSS/JSON/YAML/Markdown | prettier         |
| Lua                         | stylua           |
| Shell                       | shfmt            |

## Commands

| Command                | Action                        |
| ---------------------- | ----------------------------- |
| `:Lazy`                | Plugin manager                |
| `:Lazy sync`           | Update all plugins            |
| `:Mason`               | LSP/tool installer            |
| `:TSUpdate`            | Update all treesitter parsers |
| `:TSInstall <lang>`    | Install treesitter parser     |
| `:ConformInfo`         | Show formatter info           |
| `:FormatDisable`       | Disable format on save        |
| `:FormatEnable`        | Enable format on save         |
| `:checkhealth vim.lsp` | Check LSP status              |

## Customization

### Add a new plugin

Create a file in `lua/plugins/` (e.g., `lua/plugins/myplugin.lua`):

```lua
return {
  {
    "author/plugin-name",
    event = "VeryLazy",
    opts = {
      -- plugin options
    },
  },
}
```

### Add a new language server

1. Add to `ensure_installed` in mason-lspconfig section of `lua/plugins/lsp.lua`
2. Add configuration:

```lua
vim.lsp.config("server_name", {
  capabilities = capabilities,
  settings = {
    -- server settings
  },
})
```

3. Add to `vim.lsp.enable()` list

### Add a new formatter

Add to `formatters_by_ft` in `lua/plugins/formatting.lua`:

```lua
newlang = { "formatter1", "formatter2" },
```

## Updating

### Update all plugins

```vim
:Lazy sync
```

### Update treesitter parsers

```vim
:TSUpdate
```

Note: Lazy plugins auto-update when you run `:Lazy sync`. Treesitter parsers must be updated separately with `:TSUpdate`.

## Troubleshooting

### Plugins not loading

```vim
:Lazy sync
```

### LSP not working

```vim
:checkhealth vim.lsp
:Mason
```

### Treesitter issues

```vim
:TSUpdate
:TSInstall <language>
```

### Check overall health

```vim
:checkhealth
```

### Clear all plugin cache

```bash
rm -rf ~/.local/share/nvim/lazy ~/.local/state/nvim/lazy ~/.cache/nvim
```

## Neovim 0.11+ Features Used

This configuration takes advantage of Neovim 0.11+ features:

- **Native LSP API**: Uses `vim.lsp.config()` and `vim.lsp.enable()` instead of deprecated `require('lspconfig').server.setup()`
- **Native Treesitter API**: Uses `vim.treesitter.start()` and `vim.treesitter.foldexpr()`
- **Diagnostic signs**: Uses new `vim.diagnostic.config({ signs = { text = {...} } })` format
- **Inlay hints**: Built-in `vim.lsp.inlay_hint` API

## Migration from Vim

This config migrated from a VimScript setup using:
- Pathogen → lazy.nvim
- vim-go → gopls (native LSP)
- CtrlP/fzf → Telescope
- Goyo/Limelight → zen-mode/twilight
- Gundo → undotree
