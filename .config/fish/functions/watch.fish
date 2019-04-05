#!/usr/bin/env fish

function watch -d "Watch for changes and run command"
  if test (count $argv) -lt 2
    set location .
    set cmd $argv[1..-1]
  else
    set location $argv[1]
    set cmd $argv[2..-1]
  end

  echo "Watching '$location' and running '$cmd'..."
  fswatch -o $location | xargs -t -I{} "*" $cmd
end
