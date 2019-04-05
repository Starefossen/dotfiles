#!/usr/bin/env fish

function ansible-playbook-ssh -d "Run ansible-playbook with SSH"
  set mnt /usr/src/app
  set cmd ansible-playbook
  set key /root/.ssh-keys/id_rsa

  docker run -it --rm \
    -v (pwd):$mnt \
    -v $HOME/.ssh/id_rsa:$key:ro \
    -w /$mnt \
    williamyeh/ansible:debian9 \
      bash -c "eval \"\$(ssh-agent -s)\" && ssh-add $key && $cmd $argv"
end
