# Dotfiles

macOS dotfiles managed as a bare-ish git repo in `$HOME`.

## What's Here

```
~
├── .config/
│   ├── fish/           Fish shell config + Fisher plugins
│   ├── nvim/           Neovim 0.12+ config (see nvim/README.md)
│   ├── mise/           Dev tool & runtime versions
│   ├── uv/             Python package manager config
│   ├── git/            Git config fragments
│   └── cplt/           Copilot sandbox config
├── .tmux.conf          Tmux configuration + tpack plugins
├── .zshrc              Zsh configuration
├── .gitconfig          Git configuration
├── .gitignore_global   Global gitignore patterns
└── .tool-versions      asdf/mise tool versions
```

## Plugin Management

All tools use dedicated, modern plugin managers — no git submodules.
Plugins are declared in config files (tracked in git) and installed at
runtime.

| Tool       | Manager                  | Plugin list                          | Install command  |
| ---------- | ------------------------ | ------------------------------------ | ---------------- |
| **Neovim** | `vim.pack` (built-in)    | `vim.pack.add()` in `init.lua`       | auto on launch   |
| **Tmux**   | `tpack` (Homebrew)       | `@plugin` lines in `.tmux.conf`      | `tpack install`  |
| **Fish**   | `Fisher`                 | `.config/fish/fish_plugins`          | `fisher install` |

## Bootstrap (Fresh Machine)

```bash
# 1. Clone the repo
git clone <repo-url> ~

# 2. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Install core tools
brew install fish tmux neovim tpack mise

# 4. Install dev runtimes
mise install

# 5. Install tmux plugins
tpack install

# 6. Install fish plugins
fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher && fisher update'

# 7. Launch neovim (plugins auto-install)
nvim
```

## Updating Plugins

```bash
tpack update                    # tmux plugins
fish -c 'fisher update'        # fish plugins
nvim -c ':Pack update'         # neovim plugins
```
