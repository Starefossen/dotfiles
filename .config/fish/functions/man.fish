#!/usr/bin/env fish

function man
  if test "$argv[1]" = "lsof"
    echo http://danielmiessler.com/study/lsof/
  else
    command man $argv
  end
end
