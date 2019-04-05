#!/usr/bin/env fish

function checkip -d "Print this machines external IP address"
  wget http://checkip.dyndns.org/ -O - -o /dev/null | cut -d\  -f 6 | cut -d\< -f 1;
end
