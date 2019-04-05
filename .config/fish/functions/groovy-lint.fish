#!/usr/bin/env fish

function groovy-lint -d "Run Groovy Linter"
  set mnt /usr/src/app

  docker run --rm \
   -v (pwd):$mnt \
   -w $mnt \
   -u root \
   abletonag/groovylint:latest \
     python3 /opt/run_codenarc.py -- \
      -report=console \
      -includes="**/*.groovy,Jenkinfile" $argv
end
