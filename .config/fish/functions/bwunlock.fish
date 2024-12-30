function bwunlock --description "Unlock Bitwarden Vault using macOS keychain"
    set -x NODE_OPTIONS "--no-deprecation"

    set debugFlag 0
    set rawFlag 0
    set quietFlag 0

    for arg in $argv
      switch $arg
        case -h --help
          echo "Usage: bwunlock [-r|--raw] [-q|--quiet]"
          echo "  -r, --raw    Print the session key only"
          echo "  -q, --quiet  Do not print any output"
          return 0
        case -r --raw
          set rawFlag 1
        case -q --quiet
          set quietFlag 1
        case -d --debug
          set debugFlag 1
      end
    end

    # @TODO there is a bug here since we do not use the account name to get the session
    set -x BW_SESSION (security find-generic-password -s "bw_session" -w)

    set lockStatus (bw status | jq -r '.status')
    test $debugFlag -eq 1; and echo "lockStatus=$lockStatus"
    if [ "$lockStatus" = "unlocked" ]
      if [ $rawFlag -eq 1 ]
        echo -n $BW_SESSION
      else
        test $quietFlag -eq 0; and echo "Already unlocked!"
      end
      return 0
    end

    set -x BW_SESSION (bw unlock --raw)
    test $debugFlag -eq 1; and echo "session=$BW_SESSION"
    if [ "$BW_SESSION" = "" ]
      test $quietFlag -eq 0; and echo "Empty bitwarden session from \"bw unlock\", try logging on again using \"bw login\"" >&2
      return 1
    end

    set lockStatus (bw status | jq -r '.status')
    test $debugFlag -eq 1; and echo "lockStatus=$lockStatus"
    if [ "$lockStatus" = "locked" ]
      test $quietFlag -eq 0; and echo "Still unlocked!" >&2
      return 1
    end

    set userEmail (bw status | jq -r '.userEmail')
    test $debugFlag -eq 1; and echo "userEmail=$userEmail"
    if [ "$userEmail" = "" ]
      test $quietFlag -eq 0; and echo "Emoty $userEmail!" >&2
      return 1
    end

    test $quietFlag -eq 0; and echo "Updating keychain with new session"
    security add-generic-password -a "$userEmail" -s "bw_session" -w "$BW_SESSION" -U

    if [ $rawFlag -eq 1 ]
      echo -n $BW_SESSION
    else
      echo "Unlocked!"
    end
end

