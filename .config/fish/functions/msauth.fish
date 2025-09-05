function msauth --description "Get password and totp from Bitwarden for Microsoft auth"
    set debugFlag 0
    set cacheFlag 0
    set cacheTimeout 300  # 5 minutes cache for metadata only

    for arg in $argv
      switch $arg
        case -q --quiet
          set debugFlag 1
          set argv (string replace -r -- $arg $argv)
        case -c --cache
          set cacheFlag 1
          set argv (string replace -r -- $arg $argv)
      end
    end

    set user $argv[1]
    if test -z $user
      echo "Usage: msauth <username> [-q|--quiet] [-c|--cache]" >&2
      echo "  -q, --quiet  Suppress debug output" >&2
      echo "  -c, --cache  Cache item metadata (NOT credentials) for faster lookups" >&2
      return 1
    end

    # Cache file path for metadata only (never store credentials)
    set cache_dir "$HOME/.cache/msauth"
    set cache_file "$cache_dir/$user.meta.json"
    set item_id ""

    # Check metadata cache if enabled
    if test $cacheFlag -eq 1; and test -f "$cache_file"
        set cache_age (math (date +%s) - (stat -f %m "$cache_file" 2>/dev/null; or echo 0))
        if test $cache_age -lt $cacheTimeout
            test $debugFlag -eq 1; and echo "Using cached metadata for $user"
            set item_id (cat "$cache_file" | jq -r '.id // empty')
        end
    end

    # Search for item if not cached or cache expired
    if test -z "$item_id"
        test $debugFlag -eq 1; and echo "Searching Bitwarden for $user"

        set search_result (ibw --pretty list items --search login.microsoftonline.com)
        if test $status -ne 0
            echo "Failed to search Bitwarden vault" >&2
            return 1
        end

        set item_metadata (echo $search_result | jq -c ".[] | select(.login.username == \"$user\") | {id: .id, username: .login.username, name: .name}")
        if test -z "$item_metadata"
            echo "Failed to find user \"$user\" in Bitwarden vault. Check the username and try again." >&2
            return 1
        end

        set item_id (echo $item_metadata | jq -r '.id')

        # Cache only non-sensitive metadata if caching is enabled
        if test $cacheFlag -eq 1
            mkdir -p "$cache_dir"
            echo $item_metadata > "$cache_file"
            # Set restrictive permissions on cache directory
            chmod 700 "$cache_dir"
            chmod 600 "$cache_file"
            test $debugFlag -eq 1; and echo "Cached metadata for $user (no credentials stored)"
        end
    end

    test $debugFlag -eq 1; and echo "Found user in Bitwarden"

    # Get password directly from Bitwarden (never cached)
    set password (ibw get password $item_id)
    if test -z "$password"
        echo "No password found for user $user" >&2
        return 1
    end

    # Copy password to clipboard
    echo -n $password | pbcopy
    read -l -P "Got password from Bitwarden, ready to paste into microsoft auth prompt. Press enter to continue"

    # Get TOTP directly from Bitwarden (never cached)
    set totp (ibw get totp $item_id 2>/dev/null)
    if test -n "$totp"
        echo -n $totp | pbcopy
        echo "Got totp from Bitwarden, ready to paste into microsoft auth prompt"
    else
        echo "No TOTP configured for user $user"
    end
end
