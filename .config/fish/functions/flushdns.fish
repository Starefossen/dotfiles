#!/usr/bin/env fish

function flushdns -d "Flush DNS cache"
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder
end
