# Dotfiles

macOS dotfiles managed as a bare-ish git repo in `$HOME`.

## What's Here

```
~
├── .config/
│   ├── fish/           Fish shell config + Fisher plugins
│   ├── nvim/           Neovim 0.12+ config (see nvim/README.md)
│   ├── mise/           Dev tool & runtime versions
│   ├── git/            Git hooks (gitleaks pre-commit)
│   ├── uv/             Python package manager config
│   └── cplt/           Copilot sandbox config
├── .tmux.conf          Tmux configuration + tpack plugins
├── .zshrc              Zsh configuration (minimal, for Copilot terminal)
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

## Development Tools (mise)

[mise](https://mise.jdx.dev/) manages runtimes and CLI tools (replaces asdf):

| Category    | Tools                                                  |
| ----------- | ------------------------------------------------------ |
| Languages   | Go, Rust, Node (via `.tool-versions`)                  |
| Cloud / K8s | gcloud, kubectl, helm, kubectx, kustomize, kubebuilder |
| Packages    | pnpm, uv, yarn                                        |
| Other       | Bitwarden CLI, watchexec, ratchet                      |

Environment variables (Docker, FZF, Kubernetes, Go) are configured in
`.config/mise/config.toml`.

## Git Security & Hooks

- **GPG signing** — all commits and tags are auto-signed
- **gitleaks pre-commit** — global hook at `.config/git/hooks/pre-commit`
  scans staged changes for secrets; bypass with `git commit --no-verify`
- **Credential helper** — macOS Keychain (`osxkeychain`)

## Git Aliases

| Alias       | Action                                                |
| ----------- | ----------------------------------------------------- |
| `lg`        | Pretty graph log with GPG status and co-authors       |
| `c`         | Signed commit (`commit -vS`)                          |
| `p`         | Patch-add (`add -p`)                                  |
| `feature`   | Create feature branch from `origin/master`            |
| `publish`   | Push branch and open PR in browser                    |
| `unpublish` | Delete remote branch                                  |
| `amend`     | Signed amend                                          |
| `undo`      | Soft-reset last commit                                |
| `conflicts` | List files with merge conflicts                       |

## Fish Shell

**Default shell.** VI mode with `jj` mapped to escape.

Key aliases (in `config.shortcuts`):

| Alias          | Expansion                    |
| -------------- | ---------------------------- |
| `k`            | `kubectl`                    |
| `d` / `dc`     | `docker` / `docker-compose`  |
| `dsh` / `dbash` | Run container with shell     |
| `tf`           | `tofu` (OpenTofu)            |
| `vim`          | `nvim`                       |
| `npm`          | `pnpm`                       |
| `cat`          | `bat`                        |

Kube prompt (`kube_ps on/off`) shows current context/namespace in the prompt.

## Tmux

- **Smart pane navigation** — `Ctrl-h/j/k/l` integrates with Neovim splits
- **Workspace layouts** — `prefix D` / `prefix K` load saved dev layouts
- **Session persistence** — resurrect + continuum auto-save/restore sessions
- **VS Code integration** — `allow-passthrough on` for terminal sequences
- **256-color Solarized** theme

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

## Updating

```bash
tpack update                    # tmux plugins
fish -c 'fisher update'        # fish plugins
nvim -c ':Pack update'         # neovim plugins
mise upgrade                    # dev tools & runtimes
```
