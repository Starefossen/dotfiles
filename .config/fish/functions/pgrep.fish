#!/usr/bin/env fish

function pgrep -d "more info for pgrep"
  set pidlist (command pgrep -d, -x $argv)
  if test -n "$pidlist"
    ps -fp $pidlist
  end
end
