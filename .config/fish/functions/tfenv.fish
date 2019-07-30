#!/usr/bin/env fish

function tfenv -d "Run terraform with specific environment"
  if test (count $argv) -eq 0
    echo "Usage: tfenv [env] [cmd] [args]"
  else
    set env $argv[1]
    set cmd $argv[2]
    set opt $argv[3..-1]
    set envPath "env/$env"

    terraform $cmd -var-file=$envPath/(/bin/ls $envPath) $opt
  end
end
