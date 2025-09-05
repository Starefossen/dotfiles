function ibw --description "Run Bitwarden CLI with session"
    set -x NODE_OPTIONS "--no-deprecation"

    # Check if we already have a valid session in environment
    if test -n "$BW_SESSION"
        # Quick status check to see if session is still valid
        if bw status --quiet >/dev/null 2>&1
            set lock_status (bw status 2>/dev/null | jq -r '.status // "locked"')
            if test "$lock_status" = "unlocked"
                bw $argv
                return $status
            end
        end
    end

    # Get session from keychain if not available or invalid
    set -x BW_SESSION (bwunlock -r)

    if test -z "$BW_SESSION"
        echo "Error: bw_session was not found in keychain. Run 'bw login' to login to Bitwarden." >&2
        return 1
    end

    bw $argv
end
