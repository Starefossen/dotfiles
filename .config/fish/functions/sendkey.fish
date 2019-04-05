#!/usr/bin/env fish

function sendkey -d "Send ssh public key to some remote host (ssh-copy-id alternative)"
  if test -f ~/.ssh/id_rsa.pub
    if test (count $argv) -lt 2
      set port 22
    else
      set port $argv[2]
    end
    if test (count $argv) -gt 0
      ssh $argv[1] -p $port "mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; cat >> ~/.ssh/authorized_keys" < ~/.ssh/id_rsa.pub
    end
  else
    echo "There is no ~/.ssh/id_rsa.pub, please generate your keys with 'ssh-keygen'"
  end
end
