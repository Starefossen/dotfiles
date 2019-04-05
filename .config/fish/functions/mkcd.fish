#!/usr/bin/env fish

function mkcd -d "mkdir AND cd to it in one go!"
  mkdir -p $argv
  if test $status = 0
    cd $argv
  end
end
