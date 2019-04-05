#!/usr/bin/env fish

function aws -d "Run AWS CLI"
  set mnt /usr/src/app
  set cmd aws
  set img mesosphere/aws-cli:latest

  set configDir ~/.aws
  set configMnt /root/.aws

  if test -d (pwd)/.aws
    set configDir (pwd)/.aws
  end

  #set -q AWS_DEFAULT_REGION[1]; or set AWS_DEFAULT_REGION eu-west-1

  docker run -it --rm \
    -v $configDir:$configMnt \
    -v (pwd):$mnt \
    -w /$mnt \
    #-e "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" \
    #-e "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" \
    #-e "AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" \
    $img $argv
end
