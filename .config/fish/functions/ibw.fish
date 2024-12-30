function ibw --description "Run Bitwarden CLI with session"
    set -x NODE_OPTIONS "--no-deprecation"
    set -x BW_SESSION (bwunlock -r)

    if test -z "$BW_SESSION"
        echo "Error: bw_session was not found in keychain. Run 'bw login' to login to Bitwarden." >&2
        return 1
    end

    bw $argv
end
