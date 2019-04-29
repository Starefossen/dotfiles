#! /usr/bin/env fish

function gh-clone -d "clone github repository"
  cd $HOME/src/github.com; mkdir -p $argv[1]; cd $argv[1]
  git clone git@github.com:$argv[1].git .
end
