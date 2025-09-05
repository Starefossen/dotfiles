function msauth-cache-clean --description "Clean expired msauth cache files and insecure legacy cache"
    set cache_dir "$HOME/.cache/msauth"
    set cache_timeout 300  # 5 minutes
    set current_time (date +%s)

    if not test -d "$cache_dir"
        return 0
    end

    set cleaned_count 0

    # Clean new metadata cache files (.meta.json)
    for cache_file in "$cache_dir"/*.meta.json
        if test -f "$cache_file"
            set file_time (stat -f %m "$cache_file" 2>/dev/null; or echo 0)
            set age (math $current_time - $file_time)

            if test $age -gt $cache_timeout
                rm "$cache_file"
                set cleaned_count (math $cleaned_count + 1)
            end
        end
    end

    # SECURITY: Remove any legacy cache files that may contain credentials
    set legacy_cleaned 0
    for legacy_file in "$cache_dir"/*.json
        # Skip .meta.json files (already handled above)
        if not string match -q "*.meta.json" "$legacy_file"
            echo "Removing insecure legacy cache file: $(basename $legacy_file)" >&2
            rm "$legacy_file"
            set legacy_cleaned (math $legacy_cleaned + 1)
        end
    end

    if test $cleaned_count -gt 0
        echo "Cleaned $cleaned_count expired metadata cache files"
    end

    if test $legacy_cleaned -gt 0
        echo "Removed $legacy_cleaned insecure legacy cache files"
    end
end