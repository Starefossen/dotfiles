#!/usr/bin/env zsh

cleanup-node() {
    local dry_run=0
    local verbose=0

    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            -d|--dry-run)
                dry_run=1
                ;;
            -v|--verbose)
                verbose=1
                ;;
            -h|--help)
                echo "Usage: cleanup-node [OPTIONS]"
                echo ""
                echo "Remove node_modules folders and npm/yarn/pnpm caches"
                echo ""
                echo "Options:"
                echo "  -d, --dry-run    Show what would be deleted without actually deleting"
                echo "  -v, --verbose    Show detailed output"
                echo "  -h, --help       Show this help message"
                return 0
                ;;
        esac
    done

    local node_modules_count=0
    local cache_dirs_cleaned=0

    echo "🔍 Scanning for node_modules and cache directories..."
    echo ""

    # Find and remove node_modules in ~/go/src/github.com/
    if [[ -d ~/go/src/github.com ]]; then
        echo "📦 Searching for node_modules in ~/go/src/github.com/..."

        while IFS= read -r dir; do
            local size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')

            if [[ $dry_run -eq 1 ]]; then
                echo "  [DRY RUN] Would delete: $dir ($size)"
            else
                if [[ $verbose -eq 1 ]]; then
                    echo "  Deleting: $dir ($size)"
                fi
                rm -rf "$dir"
            fi

            ((node_modules_count++))
        done < <(find ~/go/src/github.com -type d -name "node_modules" -not -path "*/node_modules/*" -not -path "*/.*/*" 2>/dev/null)

        echo "  Found $node_modules_count node_modules directories"
    else
        echo "  ⚠️  Directory ~/go/src/github.com/ does not exist, skipping"
    fi

    echo ""

    # Clean npm cache
    if [[ -d ~/.npm ]]; then
        local npm_size=$(du -sh ~/.npm 2>/dev/null | awk '{print $1}')
        echo "📦 npm cache (~/.npm): $npm_size"

        if [[ $dry_run -eq 1 ]]; then
            echo "  [DRY RUN] Would run: npm cache clean --force"
        else
            if command -v npm &>/dev/null; then
                npm cache clean --force 2>/dev/null
                echo "  ✓ Cleaned npm cache"
                ((cache_dirs_cleaned++))
            else
                echo "  ⚠️  npm not found, skipping cache clean"
            fi
        fi
    fi

    # Clean yarn cache
    if [[ -d ~/.yarn ]]; then
        local yarn_size=$(du -sh ~/.yarn 2>/dev/null | awk '{print $1}')
        echo "📦 Yarn cache (~/.yarn): $yarn_size"

        if [[ $dry_run -eq 1 ]]; then
            echo "  [DRY RUN] Would run: yarn cache clean"
        else
            if command -v yarn &>/dev/null; then
                yarn cache clean 2>/dev/null
                echo "  ✓ Cleaned yarn cache"
                ((cache_dirs_cleaned++))
            else
                echo "  ⚠️  yarn not found, skipping cache clean"
            fi
        fi
    fi

    # Clean pnpm cache
    if [[ -d ~/.pnpm-store ]]; then
        local pnpm_size=$(du -sh ~/.pnpm-store 2>/dev/null | awk '{print $1}')
        echo "📦 pnpm store (~/.pnpm-store): $pnpm_size"

        if [[ $dry_run -eq 1 ]]; then
            echo "  [DRY RUN] Would run: pnpm store prune"
        else
            if command -v pnpm &>/dev/null; then
                pnpm store prune 2>/dev/null
                echo "  ✓ Cleaned pnpm store"
                ((cache_dirs_cleaned++))
            else
                echo "  ⚠️  pnpm not found, skipping cache clean"
            fi
        fi
    fi

    # Also check for ~/.cache/yarn and ~/.cache/pnpm
    if [[ -d ~/.cache/yarn ]]; then
        local yarn_cache_size=$(du -sh ~/.cache/yarn 2>/dev/null | awk '{print $1}')
        echo "📦 Yarn cache (~/.cache/yarn): $yarn_cache_size"

        if [[ $dry_run -eq 1 ]]; then
            echo "  [DRY RUN] Would delete: ~/.cache/yarn"
        else
            rm -rf ~/.cache/yarn
            echo "  ✓ Removed ~/.cache/yarn"
            ((cache_dirs_cleaned++))
        fi
    fi

    if [[ -d ~/.cache/pnpm ]]; then
        local pnpm_cache_size=$(du -sh ~/.cache/pnpm 2>/dev/null | awk '{print $1}')
        echo "📦 pnpm cache (~/.cache/pnpm): $pnpm_cache_size"

        if [[ $dry_run -eq 1 ]]; then
            echo "  [DRY RUN] Would delete: ~/.cache/pnpm"
        else
            rm -rf ~/.cache/pnpm
            echo "  ✓ Removed ~/.cache/pnpm"
            ((cache_dirs_cleaned++))
        fi
    fi

    echo ""
    echo "✨ Summary:"
    echo "  node_modules directories: $node_modules_count"
    echo "  Cache locations cleaned: $cache_dirs_cleaned"

    if [[ $dry_run -eq 1 ]]; then
        echo ""
        echo "💡 This was a dry run. Use 'cleanup-node' without --dry-run to actually delete."
    fi
}

# If script is sourced, don't run automatically
# If executed directly, run the function
if [[ "${(%):-%x}" == "${0}" ]]; then
    cleanup-node "$@"
fi
