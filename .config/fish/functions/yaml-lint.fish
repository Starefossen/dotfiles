#!/usr/bin/env fish

function yaml-lint -d "Run yaml-lint command"
  set mnt /usr/src/app
  set cmd yamllint

  docker run -it --rm \
    -v (pwd):$mnt \
    -w /$mnt \
    sdesbure/yamllint:latest $cmd .
end
