#!/usr/bin/fish

function gcreds -d "Set google credentials"
  gcloud config set project $argv[1] > /dev/null

  set path ~/.gcloud/$argv[1].json
  if test -f $path
    set -gx GOOGLE_APPLICATION_CREDENTIALS $path
    set -gx GOOGLE_CREDENTIALS (cat $path | tr -d '\n')
  else
    echo "File $path does not exist...."
  end
end
