function msauth
    set user $argv[1]
    if test -z $user
      echo "Usage: msauth <username>"
      return 1
    end

    set session (security find-generic-password -s "bw_session" -w)
    set id (bw --session $session --pretty list items --search login.microsoftonline.com | jq -r ".[] | select(.login.username == \"$user\") | .id")
    if test -n $id
        echo "Found user in Bitwarden"
        bw --session $session get password $id | pbcopy
        read -l -P "Got password from Bitwarden, ready to paste into microsoft auth prompt. Press enter to continue"
        bw --session $session get totp $id | pbcopy
        echo "Got totp from Bitwarden, ready to paste into microsoft auth prompt"
    else
        echo "Failed to find user $user in Bitwarden"
    end
end
