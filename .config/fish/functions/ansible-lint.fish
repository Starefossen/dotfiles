#!/usr/bin/env fish

function ansible-lint -d "Run ansible-lint command"
  set mnt /usr/src/app
  #set cmd ansible-lint

  docker run -it --rm \
    -v (pwd):$mnt \
    -w /$mnt \
    yokogawa/ansible-lint:latest \
			sh -c 'find . -name "*.y*ml" | xargs -r ansible-lint --force-color'
end
