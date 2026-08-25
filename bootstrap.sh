#!/usr/bin/env bash
#
# bootstrap.sh — set up a fresh macOS machine from this dotfiles repo.
#
# Usage:
#   ./bootstrap.sh
#
# Idempotent: every step is guarded, so it is safe to re-run at any time.
# Steps that are already done are skipped with a message.

set -euo pipefail

# Ask for the administrator password upfront to prevent hidden sudo prompts from hanging the script
printf "==> Requesting sudo access for setup...\n"
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

step() { printf '\n==> %s\n' "$1"; }
info() { printf '    %s\n' "$1"; }
warn() { printf '    warn: %s\n' "$1" >&2; }

###############################################################################
# 1. Homebrew
###############################################################################

step "Homebrew"
if command -v brew >/dev/null 2>&1; then
  info "already installed ($(command -v brew))"
else
  info "installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make brew available in this shell even on a first install.
if ! command -v brew >/dev/null 2>&1; then
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$candidate" ]; then
      eval "$("$candidate" shellenv)"
      break
    fi
  done
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "error: brew not found on PATH after install" >&2
  exit 1
fi

###############################################################################
# 2. Brewfile
###############################################################################

step "Homebrew bundle (~/Brewfile)"
if [ -f "$HOME/Brewfile" ]; then
  info "note: 'mas' entries require you to be signed in to the App Store."
  info "note: verbose mode (-v) is enabled so you can see large downloads (like Xcode) progressing."
  brew bundle install -v --file="$HOME/Brewfile" ||
    warn "some bundle entries failed (App Store sign-in? licensed app?) — re-run after fixing"
else
  warn "no ~/Brewfile found — skipping"
fi

###############################################################################
# 3. mise (runtimes & CLI tools)
###############################################################################

step "mise runtimes"
if command -v mise >/dev/null 2>&1; then
  mise install
  mise reshim
else
  warn "mise not found — skipping (is it in the Brewfile?)"
fi

###############################################################################
# 4. tmux plugins
###############################################################################

step "tmux plugins (tpack)"
if command -v tpack >/dev/null 2>&1; then
  tpack install
else
  warn "tpack not found — skipping"
fi

###############################################################################
# 5. fish plugins (fisher)
###############################################################################

step "fish plugins (fisher)"
if command -v fish >/dev/null 2>&1; then
  if [ -f "$HOME/.config/fish/functions/fisher.fish" ]; then
    info "fisher already installed"
  else
    info "installing fisher..."
    fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
  fi
  fish -c 'fisher update' || warn "fisher update failed"
else
  warn "fish not found — skipping"
fi

###############################################################################
# 5b. Default Shell
###############################################################################

step "Default Shell"
if command -v fish >/dev/null 2>&1; then
  if [ "$SHELL" != "$(command -v fish)" ]; then
    # We must read directly from /dev/tty because bootstrap.sh might be piped
    printf "    fish is not your default shell. Set it now? (requires password) [y/N]: "
    read -r response </dev/tty || response="N"
    if [[ "$response" =~ ^[Yy]$ ]]; then
      FISH_PATH=$(command -v fish)
      if ! grep -q "$FISH_PATH" /etc/shells; then
        echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
      fi
      chsh -s "$FISH_PATH"
      info "default shell changed to fish"
    else
      info "skipped changing default shell"
    fi
  else
    info "already using fish"
  fi
else
  warn "fish not found — skipping default shell setup"
fi

###############################################################################
# 6. Neovim
###############################################################################

step "Neovim plugins"
info "no action needed — vim.pack installs plugins automatically on first launch of nvim"

###############################################################################
# 7. Claude Code plugins
###############################################################################

step "Claude Code plugins"
if command -v claude >/dev/null 2>&1; then
  marketplaces=$(claude plugin marketplace list 2>/dev/null || true)

  add_marketplace() {
    local repo="$1"
    if printf '%s' "$marketplaces" | grep -qi -- "$repo"; then
      info "marketplace already added: $repo"
    else
      info "adding marketplace: $repo"
      claude plugin marketplace add "$repo" || warn "could not add marketplace $repo"
    fi
  }

  add_marketplace "anthropics/claude-plugins-official"
  add_marketplace "DietrichGebert/ponytail"
  add_marketplace "JuliusBrussee/caveman"

  for plugin in \
    "gopls-lsp@claude-plugins-official" \
    "ponytail@ponytail" \
    "caveman@caveman"; do
    info "installing plugin: $plugin"
    claude plugin install "$plugin" || warn "plugin $plugin not installed (already present?)"
  done
else
  warn "claude CLI not found — skipping Claude Code plugins"
fi

###############################################################################
# 8. Local git identity
###############################################################################

step "Git identity (~/.gitconfig.local)"
if [ -f "$HOME/.gitconfig.local" ]; then
  info "already present"
else
  warn "missing — create it manually (it is intentionally NOT tracked in git):"
  cat <<'EOF'

    # ~/.gitconfig.local
    [user]
      name = Your Name
      email = your.email@example.com
      signingkey = YOUR_GPG_KEY_ID

EOF
fi

###############################################################################
# 9. iCloud Downloads
###############################################################################

step "iCloud Downloads Symlink"
if [ -L "$HOME/Downloads" ]; then
  info "already symlinked"
else
  icloud_dl="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads"
  mkdir -p "$icloud_dl"
  
  if [ -d "$HOME/Downloads" ] && [ -z "$(ls -A "$HOME/Downloads" 2>/dev/null)" ]; then
    info "linking ~/Downloads to iCloud Drive..."
    rm -rf "$HOME/Downloads"
    ln -s "$icloud_dl" "$HOME/Downloads"
  else
    warn "~/Downloads is not empty or cannot be removed. Symlink it manually later."
  fi
fi

###############################################################################
# Summary
###############################################################################

cat <<'EOF'

===============================================================================
Bootstrap finished. MANUAL follow-ups — none of these can be automated:
===============================================================================

  1.  Sign in to the Mac App Store, then re-run:
        brew bundle install --file=~/Brewfile

  2.  Transfer secrets securely from the old machine (never over plain email
      or chat) — ideally by encrypted archive or direct cable/AirDrop:
        ~/.ssh/                        SSH keys + config
        ~/.gnupg/                      GPG keyring (commit signing)
        ~/.config/sops/age/keys.txt    age key for sops

  3.  Re-authenticate CLI tools:
        gcloud auth login && gcloud auth application-default login
        gh auth login
        copilot  (sign in on first run)
        claude   (sign in on first run)
        bw login
        nais / naisdevice  (device enrolment + login)

  4.  Re-add secrets to the macOS Keychain:
        fnox   # NAV_AI_API_KEY

  5.  Restore licence keys for paid apps (see "licensed" comments in
      ~/Brewfile): Little Snitch, Proxyman, Screen Studio, and the
      Rogue Amoeba apps (Audio Hijack, Farrago, Fission, Loopback).

  6.  Start the container runtime:
        colima start

  7.  Create ~/.gitconfig.local if the step above told you to.

  8.  System Tweaks:
        - Remap Caps Lock to Control in System Settings > Keyboard.
        - Enable "Desktop & Documents Folders" in iCloud Settings.
        - Enable Touch ID for sudo (check README.md for the snippet).

===============================================================================
EOF
