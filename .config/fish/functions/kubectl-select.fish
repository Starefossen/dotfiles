#!/usr/bin/env fish

function kubectl-select -d "Select kubectl config"
  set pwd (pwd)
  cd ~/.kube
  ln -vsf config."$argv" config
  cd $pwd
end
