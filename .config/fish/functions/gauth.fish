function gauth
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
      echo "Usage: gauth <username>"
      return 1
    end

    set id (ibw --pretty list items --search google | jq -r ".[] | select(.login.username == \"$user\") | .id")
    if [ "$id" = "" ]
        echo "Failed to find user \"$user\" in Bitwarden vault. Check the username and try again." >&2
        return 1
    end

    test $debugFlag -eq 1; and echo "Found user in Bitwarden"

    ibw get password $id | pbcopy
    echo "Got password from Bitwarden, ready to paste into google auth prompt"
    gcloud auth login --update-adc $user
end
