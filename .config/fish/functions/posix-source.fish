#!/usr/bin/env fish

function posix-source -d "Source POSIX formatted env variables"
    if not test -f "$argv[1]"
        echo "Error: file $argv[1] not found"
        return 1
    end

    for i in (cat $argv[1])
        # Skip empty lines and comments
        if string match -q -r '^\s*(#|$)' "$i"
            continue
        end

        # Remove optional "export " prefix
        set i (string replace -r '^export\s+' '' "$i")

        # Split by the first '='
        set arr (string split -m 1 '=' "$i")
        set key $arr[1]
        set val $arr[2]

        if test -n "$key"
            # Remove surrounding quotes from value if present
            set val (string replace -r '^[\'"](.*)[\'"]$' '$1' "$val")
            set -gx $key "$val"
        end
    end
end
