#!/usr/bin/env bash
#
# transfer.sh — Securely migrate workspaces, history, and secrets from the old Mac via SSH.
#
# Usage:
#   ./transfer.sh <old-machine-ip> [username]
#

set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <old-machine-ip> [username (default: $USER)]"
    exit 1
fi

OLD_IP="$1"
OLD_USER="${2:-$USER}"

echo "==============================================================================="
echo " Secure Data Transfer (SSH / rsync)"
echo "==============================================================================="
echo " Source:      $OLD_USER@$OLD_IP"
echo " Destination: $HOME"
echo ""
echo " SAFETY GUARANTEES:"
echo " - Uses 'rsync --update': Skips files that are newer on this new machine."
echo " - No Deletions: Will NEVER delete any files on this new machine."
echo " - Graceful skips: If a folder doesn't exist on the old Mac, it safely skips it."
echo "==============================================================================="
printf " Ready to transfer? [y/N]: "
read -r response </dev/tty || response="N"
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# List of paths to transfer (relative to the home directory)
ITEMS=(
    # Secrets & Configs
    ".ssh"
    ".gnupg"
    ".config/sops"
    
    # Terminal History
    ".zsh_history"
    ".bash_history"
    ".local/share/fish/fish_history"
    
    # Workspaces & Code
    "go"
    "copilot"
    "copilot-worktrees"
    "mlx-workspace"
    "minmal-maven"
    "examples"
    
    # Media
    "Screen Studio Projects"
)

echo ""

for item in "${ITEMS[@]}"; do
    echo "==> Syncing ~/$item ..."
    
    # Ensure the parent directory exists on the new machine
    DEST_DIR="$HOME/$(dirname "$item")"
    mkdir -p "$DEST_DIR"
    
    # Use -a (archive), -v (verbose), -z (compress), -u (update/skip newer), -P (progress)
    # The double quotes around the remote path handle spaces in folder names like "Screen Studio Projects"
    if ! rsync -avzuP -e ssh "$OLD_USER@$OLD_IP:\"$item\"" "$DEST_DIR/" 2>/dev/null; then
        echo "    (Skipped ~/$item - likely does not exist on the old machine)"
    fi
    echo ""
done

echo "==============================================================================="
echo " Transfer complete! 🎉"
echo " (You may want to run 'colima start' and restart your terminal now)."
echo "==============================================================================="
