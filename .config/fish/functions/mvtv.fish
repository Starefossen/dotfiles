#!/usr/bin/env fish

function mvtv -d "Send to mediaserver"
  set path (echo -n "L1ZvbHVtZXMvMiBUQiBMYUNpZS9GaWxtZXIvVFY=" | base64 --decode)
  set show $argv[1]
  set season $argv[2]
  set src $argv[3..-1]

  scp -v $src mediaserver:"'$path/$show/Season $season/'"
end
