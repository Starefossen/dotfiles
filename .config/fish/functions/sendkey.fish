#!/usr/bin/env fish

function sendkey -d "Send ssh public key to some remote host (ssh-copy-id alternative)"
  set fileName ~/.ssh/id_ed25519.pub

  if test -f $fileName
    if test (count $argv) -lt 2
      set port 22
    else
      set port $argv[2]
    end
    if test (count $argv) -gt 0
      ssh $argv[1] -p $port "mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; cat >> ~/.ssh/authorized_keys" < $fileName
    end
  else
    echo "There is no " $filename ", please generate your keys with 'ssh-keygen'"
  end
end
