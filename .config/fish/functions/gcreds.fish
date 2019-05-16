#!/usr/bin/fish

function gcreds -d "Set google credentials"
  set project $argv[1]

  gcloud config set project $project > /dev/null
  set -gx TERRAFORM_STATE_GCP_BUCKET $project-tf-state

  set encryption_key ~/.gcloud/$project.enc
  if test -f $encryption_key
    set -gx GOOGLE_ENCRYPTION_KEY (cat $encryption_key)
  else
    set -ge GOOGLE_ENCRYPTION_KEY
  end

  set credentials ~/.gcloud/$project.json
  if test -f $credentials
    set -gx GOOGLE_APPLICATION_CREDENTIALS $credentials
    set -gx GOOGLE_CREDENTIALS (cat $credentials | tr -d '\n')
  else
    echo "File $path does not exist...."
  end
end
