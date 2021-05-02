#!/usr/bin/env fish

function terraform -d "Run terraform command"
  set tfversion $argv[1]
  set tfargs $argv[2..-1]

  set mnt /root/project
  set cmd terraform

  set env_file
  if test -f .env
    set env_file "--env-file=.env"
  end

  docker run -it --rm \
    -v (pwd):$mnt \
    -v ~/.azure:/root/.azure \
    -v ~/.helm:/root/.helm \
    -v ~/.kube:/root/.kube \
    -v ~/.terraform.d:/root/.terraform.d \
    #-v ~/.gitconfig:/root/.gitconfig \
    -v /etc/hosts:/etc/hosts \
    -w /$mnt \
    -e GOOGLE_CREDENTIALS \
    -e GOOGLE_ENCRYPTION_KEY \
    (env | grep TF_ | cut -f1 -d= | sed 's/^/-e /') \
    $env_file \
    #--entrypoint /bin/sh \
    hashicorp/terraform:$tfversion $tfargs
end
