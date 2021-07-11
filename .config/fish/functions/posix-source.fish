#!/usr/bin/env fish

function posix-source
	for i in (cat $argv)
    if test -n "$i"
      set arr (echo $i |tr = \n)
      if test (count $arr) -eq 2
        echo "Setting $arr[1]"
        set -gx $arr[1] $arr[2]
      end
    end
	end
end
