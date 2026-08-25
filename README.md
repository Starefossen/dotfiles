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

[mise](https://mise.jdx.dev/) manages runtimes and CLI tools (replaces asdf and Homebrew for standalone binaries):

| Category    | Tools                                                                 |
| ----------- | --------------------------------------------------------------------- |
| Languages   | Go, Rust, Node                                                        |
| Cloud / K8s | gcloud, kubectl, helm, kubectx, kustomize, kubebuilder                |
| Packages    | pnpm, uv, yarn                                                        |
| Terminal    | bat, delta, difftastic, fd, fzf, jq, yq                               |
| Utilities   | actionlint, Bitwarden CLI, gh, gitleaks, lefthook, ratchet, watchexec |

Environment variables (Docker, FZF, Kubernetes, Go) are configured in
`.config/mise/config.toml`.

## Git Security & Hooks

- **GPG signing** — all commits and tags are auto-signed
- **gitleaks pre-commit** — global hook at `.config/git/hooks/pre-commit` acts as a dispatcher for `lefthook`. To scan staged changes for secrets, a `lefthook.yml` (or `.lefthook.yml`) must be present in the repository root (as seen in this repo). Bypass with `git commit --no-verify`
- **co-author pre-push** — global hook at `.config/git/hooks/pre-push`
  warns before pushing unsigned commits with Co-authored-by trailers;
  bypass with `git push --no-verify`
- **Credential helper** — macOS Keychain (`osxkeychain`)

### Personal Identity (`.gitconfig.local`)

This repository is a generic template. To set your Git name, email, and signing key, create a `~/.gitconfig.local` file (this file is ignored by Git). The main `.gitconfig` will automatically include it:

```ini
[user]
  name = Your Name
  email = your.email@example.com
  signingkey = YOUR_GPG_KEY_ID
```

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
| `claim`     | Re-sign last N commits, strip Co-authored-by trailers |
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

### Key Bindings

| Binding       | Action                                          |
| ------------- | ----------------------------------------------- |
| `prefix + s`  | Session chooser (with 🔔/⚡ alert indicators)  |
| `prefix + w`  | List windows in current session                 |
| `prefix + m`  | Toggle monitor-activity for current window      |
| `prefix + b`  | Toggle status bar                               |
| `prefix + D`  | Load dev workspace layout                       |
| `prefix + K`  | Load dev2 workspace layout                      |
| `prefix + \|` | Split pane horizontally                         |
| `prefix + S`  | Split pane vertically                           |
| `prefix + c`  | New window (in current path)                    |
| `prefix + z`  | Toggle pane zoom (fullscreen)                   |
| `prefix + j`  | Join pane from another window                   |
| `prefix + J`  | Break pane into its own window                  |
| `prefix + T`  | Rename window                                   |
| `prefix + r`  | Reload tmux config                              |
| `` prefix + ` `` | Open man page in split                       |

### Window Alert Flags

Windows with alerts are highlighted in the status bar with these flags:

| Flag | Meaning                                  |
| ---- | ---------------------------------------- |
| `!`  | Bell occurred (red/bold)                 |
| `#`  | Activity detected (yellow)               |
| `~`  | Silence — no output for N seconds        |

In the session chooser (`prefix + s`), sessions with alerts show 🔔 and
⚡ followed by the window indexes that triggered the alert.

## Bootstrap (Fresh Machine)

```bash
# 1. Clone the repo into $HOME
git clone <repo-url> ~

# 2. Run the bootstrap script (idempotent — safe to re-run)
cd ~ && ./bootstrap.sh
```

`bootstrap.sh` installs Homebrew, runs `brew bundle` against
[`Brewfile`](Brewfile) (formulae, casks, App Store apps via `mas`, VS Code
extensions), then sets up mise runtimes, tmux plugins (`tpack`), fish plugins
(Fisher) and Claude Code plugins. Neovim plugins install themselves on first
launch.

### Manual follow-ups

Things the script cannot do for you:

- **Sign in to the Mac App Store**, then re-run `brew bundle install --file=~/Brewfile`
- **Re-authenticate CLIs**: `gcloud`, `gh`, `copilot`, `claude`, `bw` (Bitwarden), `nais`/`naisdevice`
- **Re-add `NAV_AI_API_KEY`** to the macOS Keychain via `fnox`
- **Restore licence keys** for paid apps (marked `licensed` in the Brewfile)
- **Start the container runtime**: `colima start`
- **Pull local LLM models**: `ollama pull <model>`
- **Create `~/.gitconfig.local`** with your name, email and signing key (see above)
- **Keyboard Settings**: Go to System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys and remap Caps Lock to Control.

### 📦 Manual Data Migration

While the bootstrap script handles applications and dependencies, your personal data and workspaces must be manually transferred from the old machine.

- **Secrets (Secure Transfer):** `~/.ssh/`, `~/.gnupg/`, `~/.config/sops/age/keys.txt`
- **Code & Workspaces:** `~/go/`, `~/copilot/`, `~/copilot-worktrees/`, `~/mlx-workspace/`, `~/minmal-maven/`, `~/examples/`
- **Media:** `~/Screen Studio Projects/` (Local screen recordings)
- **Terminal History:** `~/.zsh_history`, `~/.bash_history` (Recommended for continuity)
- **AI Agent History (Optional):** Active chat sessions in `~/.claude/`, `~/.gemini/`, `~/.nav-pilot/`, `~/.qodo/`. *(Note: AI configs like `CLAUDE.md` are tracked in this repo, but agent chat histories are intentionally ignored).*

## Cleaning up

```bash
./cleanup.sh            # clear regenerable caches (docker, npm/pnpm, brew, go, …)
./cleanup.sh --check    # report sizes only
./cleanup.sh --deep     # also go module cache and playwright browsers
./cleanup.sh --repos    # also build artifacts under ~/go/src/github.com
```

## Updating

```bash
brew bundle install --file=~/Brewfile  # packages, casks & App Store apps
tpack update                    # tmux plugins
fish -c 'fisher update'        # fish plugins
nvim -c ':Pack update'         # neovim plugins
mise upgrade                    # dev tools & runtimes
```
