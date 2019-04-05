#!/usr/bin/env fish

function servedir -d "Serve files of cwd"
  ifconfig | grep "inet addr"
  python -m SimpleHTTPServer
end
