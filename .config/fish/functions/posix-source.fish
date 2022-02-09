#!/usr/bin/env fish

function posix-source
	for i in (cat $argv)
    if test -n "$i"
      set key (echo $i | cut -d '=' -f 1)
      set val (echo $i | cut -d '=' -f 2-)
      if test -n "$key" -a -n "$val"
        echo "Setting $key"
        set -gx $key $val
      end
    end
	end
end
