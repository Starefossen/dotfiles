#!/usr/bin/env fish

function ansible-playbook -d "Run ansible-playbook command"
  set mnt /usr/src/app
  set cmd ansible-playbook

  docker run -it --rm \
    -v (pwd):$mnt \
    -v $HOME/.ssh/id_rsa:/root/.ssh/id_rsa:ro \
    #-v $HOME/.ssh/prometheus-workshop:/root/.ssh/prometheus-workshop:ro \
    #-v $HOME/.ssh/config:/root/.ssh/config \
    -w /$mnt \
    williamyeh/ansible:debian9 $cmd $argv
end
