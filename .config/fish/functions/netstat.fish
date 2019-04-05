#!/usr/bin/env fish

function netstat -d "Netstat with some commonly used options"
  command sudo netstat --numeric --inet -p $argv
end
