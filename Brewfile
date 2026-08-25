# Brewfile — Homebrew package manifest for a fresh macOS machine
#
# Install everything with:
#   brew bundle install --file=~/Brewfile
#
# This file targets a FRESH machine: it includes casks for apps that were
# previously installed manually (drag-to-Applications, vendor installers) or
# from the Mac App Store, so that everything is managed by Homebrew from now on.
#
# `mas` entries require you to be signed in to the App Store first.
# See bootstrap.sh for the full machine setup flow.

###############################################################################
# Taps
###############################################################################

tap "anomalyco/tap", trusted: true
tap "azure/kubelogin", trusted: true
tap "charmbracelet/tap", trusted: true
tap "cloudnativebergen/tap", "https://github.com/CloudNativeBergen/homebrew-tap", trusted: true
tap "domt4/autoupdate", "https://github.com/DomT4/homebrew-autoupdate.git", trusted: true
tap "humanlogio/tap", trusted: true
tap "jjuarez/tap-1", trusted: true
tap "kanidm/kanidm", trusted: true
tap "nais/tap", trusted: true
tap "navikt/tap", trusted: true
tap "tmuxpack/tpack", trusted: true
tap "runkonf/tap", trusted: true

###############################################################################
# CLI tools & libraries (formulae)
###############################################################################

# Simple, modern, secure file encryption
brew "age"
# Resource monitor. C++ version and continuation of bashtop and bpytop
brew "btop"
# Perl compatible regular expressions library with a new API
brew "pcre2"
# Cross-platform make
brew "cmake"
# Linux virtual machines
brew "lima"
# Container runtimes on MacOS (and Linux) with minimal setup
brew "colima"
# GNU File, Shell, and Text utilities
brew "coreutils"
# Pack, ship and run any application as a lightweight container
brew "docker"
# Docker CLI plugin for extended build capabilities with BuildKit
brew "docker-buildx"
# Isolated development environments using Docker
brew "docker-compose"
# Perl lib for reading and writing EXIF metadata
brew "exiftool"
# Cryptography and SSL/TLS Toolkit
brew "openssl@3"
# Play, record, convert, and stream select audio and video codecs
brew "ffmpeg"
# User-friendly command-line shell for UNIX-like operating systems
brew "fish"
# Distributed revision control system
brew "git"
# Quickly rewrite git repository history
brew "git-filter-repo"
# HTTP load generator, ApacheBench (ab) replacement
# Logs for humans to read
# Postgres C API library
brew "libpq", link: true
# Library to render SVG files using Cairo
brew "librsvg"
# Mac App Store command-line interface
brew "mas"
# Polyglot runtime manager (asdf rust clone)
brew "mise"
# Ambitious Vim-fork focused on extensibility and agility
brew "neovim"
# PAM module for reattaching to the user's GUI (Aqua) session
brew "pam-reattach"
# Pinentry for GPG on Mac
brew "pinentry-mac"
# PDF rendering library (based on the xpdf-3.0 code base)
brew "poppler"
# Reattach process (e.g., tmux) to background
# Search tool like grep and The Silver Searcher
brew "ripgrep"
# CLI proxy to minimize LLM token consumption
brew "rtk"
# Static analysis and lint tool, for (ba)sh scripts
brew "shellcheck"
# Editor of encrypted files
brew "sops"
# Generate type safe Go from SQL
brew "sqlc"
# Terminal multiplexer
brew "tmux"
# Upgrade all the things
brew "topgrade"
# Drop-in replacement for tmux-plugin-manager (tpm) with a TUI
brew "tpack", link: false
# Internet file retriever
# Tools for the WireGuard secure network tunnel
brew "wireguard-tools"
# Feature-rich command-line audio/video downloader
brew "yt-dlp"
# The AI coding agent built for the terminal.
brew "anomalyco/tap/opencode", trusted: true
# Nav's institutional AI developer toolkit for GitHub Copilot
brew "navikt/tap/nav-pilot", trusted: true
# macOS Seatbelt sandbox wrapper for GitHub Copilot CLI
brew "navikt/tap/cplt", trusted: true
# CLI for Konf — run your conference (konfctl releases)
brew "runkonf/tap/konf"

###############################################################################
# Development & terminal apps
###############################################################################

# Terminal-based AI coding assistant
cask "claude-code@latest"
# Brings the power of Copilot coding agent directly to your terminal
cask "copilot-cli@prerelease"
# Code editor
cask "visual-studio-code"
cask "finicky"
cask "antigravity-cli"
cask "openusage"
# JDK from the Eclipse Foundation (Adoptium)
cask "temurin"
# Reverse proxy, secure introspectable tunnels to localhost
cask "ngrok"
# Application for inspecting installer packages
cask "suspicious-package"
# Tmux Plugin Manager
cask "tmuxpack/tpack/tpack", trusted: true
# Nav developer VPN / device client
cask "naisdevice"
# Virtual machines for macOS
cask "utm"

###############################################################################
# Security & privacy
###############################################################################

# GPG suite (GPG Keychain, GPG Mail, pinentry UI)
cask "gpg-suite"
# Host-based application firewall
cask "little-snitch" # licensed — restore key from vault
# HTTP debugging proxy
cask "proxyman" # licensed — restore key from vault

###############################################################################
# Browsers
###############################################################################

# Firefox Developer Edition
cask "firefox@developer-edition"

###############################################################################
# Communication
###############################################################################

cask "discord"
cask "signal"
cask "zoom"
cask "microsoft-teams"

###############################################################################
# Media, audio & creative
###############################################################################

# Screen recording with automatic zoom/pan
cask "screen-studio" # licensed — restore key from vault
# RODE interface configuration utilities
cask "rode-central"

###############################################################################
# Design & productivity
###############################################################################

cask "figma"
# Uninstaller that finds leftover files
cask "appcleaner"

###############################################################################
# Not available as a Homebrew cask
###############################################################################

# bluesky — no cask exists (`brew search bluesky` finds nothing).
#   Install the Bluesky app manually, or just use https://bsky.app in a browser.

###############################################################################
# App Store -> Homebrew cask migrations
#
# On the OLD machine these four are Mac App Store installs. On this machine
# they are managed by Homebrew instead. If you ever run `brew bundle` on the
# old machine, REMOVE the App Store copies first to avoid duplicate installs.
###############################################################################

cask "tailscale-app"
cask "slack"
mas "Bitwarden", id: 1352778147
cask "mp3tag"

###############################################################################
# Mac App Store only (requires `mas` + being signed in to the App Store)
###############################################################################

mas "PiPifier", id: 1160374471
mas "uBlock Origin Lite", id: 6745342698
mas "Ghostery Privacy Ad Blocker", id: 6504861501

###############################################################################
# VS Code extensions
###############################################################################

vscode "bierner.markdown-mermaid"
vscode "bradlc.vscode-tailwindcss"
vscode "connor4312.esbuild-problem-matchers"
vscode "davidanson.vscode-markdownlint"
vscode "dbaeumer.vscode-eslint"
vscode "esbenp.prettier-vscode"
vscode "github.copilot-chat"
vscode "github.github-vscode-theme"
vscode "github.vscode-github-actions"
vscode "github.vscode-pull-request-github"
vscode "golang.go"
vscode "hashicorp.terraform"
vscode "joselitofilho.ginkgotestexplorer"
vscode "ms-python.debugpy"
vscode "ms-python.isort"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-python.vscode-python-envs"
vscode "ms-vscode.makefile-tools"
vscode "ms-vscode.vscode-typescript-next"
vscode "onsi.vscode-ginkgo"
vscode "redhat.vscode-yaml"
vscode "sanity-io.vscode-sanity"
vscode "streetsidesoftware.code-spell-checker"
vscode "streetsidesoftware.code-spell-checker-norwegian-bokmal"
vscode "vscodevim.vim"
vscode "yzhang.markdown-all-in-one"

###############################################################################
# Language toolchains (go / cargo / npm)
###############################################################################

cargo "cargo-audit"
cargo "cargo-zigbuild"
# cnctl is deprecated — replaced by konfctl (brew "runkonf/tap/konf" above)

###############################################################################
# Fonts
###############################################################################

cask "font-jetbrains-mono-nerd-font"
mas "Hush Nag Blocker", id: 1544743900
