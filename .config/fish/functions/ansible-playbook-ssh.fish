#!/usr/bin/env fish

function ansible-playbook-ssh -d "Run ansible-playbook with SSH"
  set mnt /usr/src/app
  set cmd ansible-playbook
  set cmd bash
  set key /root/.ssh-keys/id_rsa

  set sshDir (dm ssh default ls /tmp/ | grep ssh)
  set sshAgent (dm ssh default ls /tmp/$sshDir/)

  docker run -it --rm \
    -v (pwd):$mnt \
    -v $HOME/.ssh/id_rsa:/root/.ssh/id_rsa:ro \
    -v $HOME/.ssh/known_hosts:/root/.ssh/known_hosts:ro \
    -v /tmp/$sshDir:/ssh-agent \
    -e SSH_AUTH_SOCK=/ssh-agent/$sshAgent \
    -e ANSIBLE_SSH_ARGS="-o ControlMaster=auto -o ControlPersist=60s -o ControlPath=/tmp/ansible-ssh-%h-%p-%r -o ForwardAgent=yes -o StrictHostKeyChecking=no" \
    -w /$mnt \
    #cytopia/ansible:latest-tools $cmd $argv
    williamyeh/ansible:master-ubuntu16.04 $cmd $argv #\
      #bash -c "eval \"\$(ssh-agent -s)\" && ssh-add $key && $cmd $argv"
end
