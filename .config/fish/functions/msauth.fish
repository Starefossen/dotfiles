function msauth --description "Get password and totp from Bitwarden for Microsoft auth"
    set debugFlag 0

    for arg in $argv
      switch $arg
        case -q --quiet
          set debugFlag 1
          set argv (string replace -r -- $arg $argv)
      end
    end

    set user $argv[1]
    if test -z $user
      echo "Usage: msauth <username> [-q|--quiet]" >&2
      return 1
    end

    set id (ibw --pretty list items --search login.microsoftonline.com | jq -r ".[] | select(.login.username == \"$user\") | .id")
    if [ "$id" = "" ]
        echo "Failed to find user \"$user\" in Bitwarden vault. Check the username and try again." >&2
        return 1
    end

    test $debugFlag -eq 1; and echo "Found user in Bitwarden"

    ibw get password $id | pbcopy
    read -l -P "Got password from Bitwarden, ready to paste into microsoft auth prompt. Press enter to continue"
    ibw get totp $id | pbcopy
    echo "Got totp from Bitwarden, ready to paste into microsoft auth prompt"
end
