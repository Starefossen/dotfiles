#!/usr/bin/env fish

function gitlab -d "Run terraform command"
  set mnt /root/project
  set cmd gitlab

  set env_file
  if test -f .env
    set env_file "--env-file=.env"
  end

  docker run -it --rm \
    -v (pwd):$mnt \
    -v ~/.config/gitlab/config.cfg:/root/.python-gitlab.cfg \
    -w /$mnt \
    (env | grep GITLAB_ | cut -f1 -d= | sed 's/^/-e /') \
    $env_file \
    --entrypoint gitlab \
    starefossen/python-gitlab:latest $argv
end
