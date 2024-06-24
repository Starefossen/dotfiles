function ibw
    set session (security find-generic-password -s "bw_session" -w)

    if test -z $session
        echo "Error: bw_session was not found in keychain. Run 'bw login' to login to Bitwarden."
        return 1
    end

    bw --session $session $argv
end
