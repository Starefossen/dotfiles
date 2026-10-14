function ibw --description "Run Bitwarden CLI with session; 'ibw backup-k8s' copies homelab secrets to Bitwarden folder Landåsveien/k8s"
    set -x NODE_OPTIONS "--no-deprecation"

    # Check if we already have a valid session in environment
    set -l have_session 0
    if test -n "$BW_SESSION"
        # Quick status check to see if session is still valid
        if bw status --quiet >/dev/null 2>&1
            set lock_status (bw status 2>/dev/null | jq -r '.status // "locked"')
            test "$lock_status" = "unlocked"; and set have_session 1
        end
    end

    if test $have_session -eq 0
        # Get session from keychain if not available or invalid
        set -x BW_SESSION (bwunlock -r)

        if test -z "$BW_SESSION"
            echo "Error: bw_session was not found in keychain. Run 'bw login' to login to Bitwarden." >&2
            return 1
        end
    end

    if test "$argv[1]" = restore-k8s
        # ibw restore-k8s <ns/name>: recreate one Secret from its k8s:<ns>/<name> note
        set -l ns (string split -m1 / $argv[2])[1]
        set -l name (string split -m1 / $argv[2])[2]
        if test -z "$name"
            echo "usage: ibw restore-k8s <ns/name>" >&2
            return 1
        end
        bw sync >/dev/null
        bw list items --search "k8s:$argv[2]" | jq -e --arg t "k8s:$argv[2]" --arg ns $ns --arg n $name \
            'map(select(.name == $t))[0] | {apiVersion: "v1", kind: "Secret", type: "Opaque", metadata: {namespace: $ns, name: $n}, stringData: (.fields | map({(.name): .value}) | add)}' \
            | kubectl apply -f -
        return $status
    end

    if test "$argv[1]" != backup-k8s
        bw $argv
        return $status
    end

    # Secrets that come from outside the cluster or cannot be regenerated.
    # One secure note per secret, named k8s:<ns>/<name>, one hidden field per key.
    set -l secrets \
        cert-manager/cert-manager-aws-credentials \
        cert-manager/namecheap-credentials \
        cert-manager/letsencrypt-prod-account-key \
        diktator/gcp-credentials \
        kanidm/idm-admin \
        kanidm/radius \
        kanidm/wifi-secrets \
        mcp/mcp-auth-token \
        mcp/mykid-credentials \
        mcp/nett-secrets \
        mcp/spond-credentials \
        mcp/varden-codesign \
        mcp/varden-updater-key \
        mcp/vigilo-credentials \
        pihole/pihole-password \
        radio/radio-auth \
        radio/radio-producer-secrets \
        skjerm/calendar-feed \
        skjerm/mcp-auth-token \
        skjerm/skjerm-secrets \
        trident/qnap-credentials \
        trident/trident-encryption-keys \
        unifier/family \
        unifier/netctl-ro \
        unifier/ntfy-token \
        unifier/ppsk-keys \
        unifier/unifi-credentials \
        wifi/kanidm-token \
        wifi/oidc \
        zot/zot-htpasswd \
        zot/zot-push

    bw sync >/dev/null
    set -l folder (bw list folders --search k8s | jq -r '.[] | select(.name == "Landåsveien/k8s") | .id')
    if test -z "$folder"
        set folder (jq -nc '{name: "Landåsveien/k8s"}' | bw encode | bw create folder | jq -r .id)
    end

    set -l failed 0
    for s in $secrets
        set -l ns (string split -m1 / $s)[1]
        set -l name (string split -m1 / $s)[2]
        set -l data (kubectl get secret -n $ns $name -o json 2>/dev/null | jq -c .data)
        if test -z "$data"
            echo "missing  $s" >&2
            set failed (math $failed + 1)
            continue
        end
        set -l title "k8s:$s"
        set -l fields (echo $data | jq -c 'to_entries | map({name: .key, value: (.value | @base64d), type: 1})')
        set -l id (bw list items --folderid $folder --search $title | jq -r --arg t $title '.[] | select(.name == $t) | .id')
        if test -n "$id"
            bw get item $id | jq -c --argjson f "$fields" '.fields = $f | .notes = "kubectl get secret -n '$ns' '$name'"' | bw encode | bw edit item $id >/dev/null
            and echo "updated  $s"
        else
            jq -nc --arg t $title --arg fo $folder --argjson f "$fields" --arg n "kubectl get secret -n $ns $name" \
                '{type: 2, secureNote: {type: 0}, name: $t, folderId: $fo, notes: $n, fields: $f}' | bw encode | bw create item >/dev/null
            and echo "created  $s"
        end
        or set failed (math $failed + 1)
    end
    bw sync >/dev/null
    test $failed -eq 0
end
