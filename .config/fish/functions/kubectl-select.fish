#!/usr/bin/env fish

function kubectl-select -d "Select kubectl config"
  ln -vsf ~/.kube/config."$argv" ~/.kube/config
end
