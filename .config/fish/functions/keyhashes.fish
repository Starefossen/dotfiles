#!/usr/bin/env fish

function keyhashes -d "View server key-hashes"
  for key in (command ls /etc/ssh/ssh_*_key.pub)
    ssh-keygen -lf $key
  end
end
