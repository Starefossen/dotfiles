#!/usr/bin/env fish

function kubectl-secret -d "Decode Kubernetes Secret"
  set secret $argv[1]
  set key $argv[2]

  kubectl get secrets $secret --template="{{.data.$key}}" # | base64 -D
end

