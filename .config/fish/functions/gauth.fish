function gauth
    set user $argv[1]
    if test -z $user
      echo "Usage: gauth <username>"
      return 1
    end

    if ibw --pretty list items --search google | jq -r ".[] | select(.login.username == \"$user\") | .login.password" | pbcopy
        echo "Got password from bitwarden, ready to paste into google auth prompt"
        gcloud auth login --update-adc $user
    else
        echo "Failed to get google password from bitwarden"
    end
end
