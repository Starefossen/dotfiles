#!/usr/bin/env fish

function terraform -d "Run terraform command"
  set mnt /root/terraform
  set cmd terraform

  set env_file
  if test -f .env
    set env_file "--env-file=.env"
  end

  docker run -it --rm \
    -v (pwd):$mnt \
    -v ~/.helm:/root/.helm \
    -v ~/.kube:/root/.kube \
    -w /$mnt \
    -e GOOGLE_CREDENTIALS \
    -e GOOGLE_ENCRYPTION_KEY \
    (env | grep TF_ | cut -f1 -d= | sed 's/^/-e /') \
    $env_file \
    hashicorp/terraform:light $argv
end
