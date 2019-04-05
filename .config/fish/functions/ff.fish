#!/usr/bin/env fish

function ff -d "Find string in current working directory using mdfind"
  if test (count $argv) -lt 2
    set location .
  else
    set location $argv[2]
  end

  for file in (mdfind -onlyin "$location" "$argv[1]")
    echo \n;
    echo "$file";
    echo \n;

    grep -in --color -A 5 -B 5 "$argv[1]" "$file"
  end
end
