# ~/.zshrc - Minimal zsh config for VS Code Copilot terminal
# This shell is used by Copilot's run_in_terminal tool

# Load environment from login shell
[[ -f ~/.zprofile ]] && source ~/.zprofile

# Homebrew (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null

# Common PATH additions
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# mise (if available)
command -v mise &>/dev/null && eval "$(mise activate zsh)"

# Minimal prompt (VS Code overrides this with shell integration)
PS1='%~ %# '

# History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# Useful aliases
alias ll='ls -la'
alias la='ls -A'

# Git aliases
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline -20'
