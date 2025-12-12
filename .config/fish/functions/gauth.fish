function gauth
    set -x NODE_OPTIONS "--no-deprecation"
    set debugFlag 1

    for arg in $argv
      switch $arg
        case -d --debug
          set debugFlag 1
          set argv (string replace -r -- $arg $argv)
      end
    end

    set username $argv[1]
    if test -z $username
      echo "Usage: gauth <username>"
      return 1
    end

    set user (ibw --pretty list items --search google | jq -r ".[] | select(.login.username == \"$username\") | {id, password: .login.password}")
    if [ "$user" = "" ]
        echo "Failed to find user \"$username\" in Bitwarden vault. Check the username and try again." >&2
        return 1
    end

    set id (echo $user | jq -r '.id')
    test $debugFlag -eq 1; and echo "Found user in Bitwarden (id: $id)"

    echo $user | jq -r '.password' | pbcopy
    echo "Got password from Bitwarden, ready to paste into google auth prompt"
    gcloud auth login --activate --update-adc $username
end
