#!/usr/bin/env fish

function fack -d "run last command as sudo"
  eval command sudo $history[1]
end
