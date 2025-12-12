function cleanup-node
    set -l dry_run 0
    set -l verbose 0

    # Parse arguments
    for arg in $argv
        switch $arg
            case -d --dry-run
                set dry_run 1
            case -v --verbose
                set verbose 1
            case -h --help
                echo "Usage: cleanup-node [OPTIONS]"
                echo ""
                echo "Remove node_modules folders and npm/yarn/pnpm caches"
                echo ""
                echo "Options:"
                echo "  -d, --dry-run    Show what would be deleted without actually deleting"
                echo "  -v, --verbose    Show detailed output"
                echo "  -h, --help       Show this help message"
                return 0
        end
    end

    set -l node_modules_count 0
    set -l cache_dirs_cleaned 0
    set -l total_space 0

    echo "🔍 Scanning for node_modules and cache directories..."
    echo ""

    # Find and remove node_modules in ~/go/src/github.com/
    if test -d ~/go/src/github.com
        echo "📦 Searching for node_modules in ~/go/src/github.com/..."

        for dir in (find ~/go/src/github.com -type d -name "node_modules" -not -path "*/node_modules/*" -not -path "*/.*/*" 2>/dev/null)
            set -l size (du -sh "$dir" 2>/dev/null | awk '{print $1}')

            if test $dry_run -eq 1
                echo "  [DRY RUN] Would delete: $dir ($size)"
            else
                if test $verbose -eq 1
                    echo "  Deleting: $dir ($size)"
                end
                rm -rf "$dir"
            end

            set node_modules_count (math $node_modules_count + 1)
        end

        echo "  Found $node_modules_count node_modules directories"
    else
        echo "  ⚠️  Directory ~/go/src/github.com/ does not exist, skipping"
    end

    echo ""

    # Clean npm cache
    if test -d ~/.npm
        set -l npm_size (du -sh ~/.npm 2>/dev/null | awk '{print $1}')
        echo "📦 npm cache (~/.npm): $npm_size"

        if test $dry_run -eq 1
            echo "  [DRY RUN] Would run: npm cache clean --force"
        else
            if command -q npm
                npm cache clean --force 2>/dev/null
                echo "  ✓ Cleaned npm cache"
                set cache_dirs_cleaned (math $cache_dirs_cleaned + 1)
            else
                echo "  ⚠️  npm not found, skipping cache clean"
            end
        end
    end

    # Clean yarn cache
    if test -d ~/.yarn
        set -l yarn_size (du -sh ~/.yarn 2>/dev/null | awk '{print $1}')
        echo "📦 Yarn cache (~/.yarn): $yarn_size"

        if test $dry_run -eq 1
            echo "  [DRY RUN] Would run: yarn cache clean"
        else
            if command -q yarn
                yarn cache clean 2>/dev/null
                echo "  ✓ Cleaned yarn cache"
                set cache_dirs_cleaned (math $cache_dirs_cleaned + 1)
            else
                echo "  ⚠️  yarn not found, skipping cache clean"
            end
        end
    end

    # Clean pnpm cache
    if test -d ~/.pnpm-store
        set -l pnpm_size (du -sh ~/.pnpm-store 2>/dev/null | awk '{print $1}')
        echo "📦 pnpm store (~/.pnpm-store): $pnpm_size"

        if test $dry_run -eq 1
            echo "  [DRY RUN] Would run: pnpm store prune"
        else
            if command -q pnpm
                pnpm store prune 2>/dev/null
                echo "  ✓ Cleaned pnpm store"
                set cache_dirs_cleaned (math $cache_dirs_cleaned + 1)
            else
                echo "  ⚠️  pnpm not found, skipping cache clean"
            end
        end
    end

    # Also check for ~/.cache/yarn and ~/.cache/pnpm
    if test -d ~/.cache/yarn
        set -l yarn_cache_size (du -sh ~/.cache/yarn 2>/dev/null | awk '{print $1}')
        echo "📦 Yarn cache (~/.cache/yarn): $yarn_cache_size"

        if test $dry_run -eq 1
            echo "  [DRY RUN] Would delete: ~/.cache/yarn"
        else
            rm -rf ~/.cache/yarn
            echo "  ✓ Removed ~/.cache/yarn"
            set cache_dirs_cleaned (math $cache_dirs_cleaned + 1)
        end
    end

    if test -d ~/.cache/pnpm
        set -l pnpm_cache_size (du -sh ~/.cache/pnpm 2>/dev/null | awk '{print $1}')
        echo "📦 pnpm cache (~/.cache/pnpm): $pnpm_cache_size"

        if test $dry_run -eq 1
            echo "  [DRY RUN] Would delete: ~/.cache/pnpm"
        else
            rm -rf ~/.cache/pnpm
            echo "  ✓ Removed ~/.cache/pnpm"
            set cache_dirs_cleaned (math $cache_dirs_cleaned + 1)
        end
    end

    echo ""
    echo "✨ Summary:"
    echo "  node_modules directories: $node_modules_count"
    echo "  Cache locations cleaned: $cache_dirs_cleaned"

    if test $dry_run -eq 1
        echo ""
        echo "💡 This was a dry run. Use 'cleanup-node' without --dry-run to actually delete."
    end
end
