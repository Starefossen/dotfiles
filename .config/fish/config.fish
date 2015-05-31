# Application specific
. ~/.config/fish/config.shortcuts
. ~/.config/fish/config.prompt
. ~/.config/fish/config.git

# Exports
set -x LC_ALL en_US.UTF-8
set -x LANG en_US.UTF-8
set -x LANGUAGE en_US.UTF-8

set -x PATH $PATH ~/bin/ # Local bin directory
set -x PATH $PATH /opt/bin/ # Tmux path

set -x DOCKER_TLS_VERIFY "1";
set -x DOCKER_HOST "tcp://192.168.99.100:2376";
set -x DOCKER_CERT_PATH "/Users/hans/.docker/machine/machines/dev";
set -x DOCKER_MACHINE_NAME "dev";
