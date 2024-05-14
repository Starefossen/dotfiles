function ibw
    set session (security find-generic-password -s "bw_session" -w)
    bw --session $session $argv
end
