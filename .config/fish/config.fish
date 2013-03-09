# Application specific
. ~/.config/fish/config.shortcuts
. ~/.config/fish/config.prompt
. ~/.config/fish/config.git

# Exports
set -x LC_ALL en_US.UTF-8
set -x LANG en_US.UTF-8
set -x LANGUAGE en_US.UTF-8

set -x PATH $PATH ~/.rvm/bin # Add RVM to PATH for scripting
set -x PATH $PATH /usr/local/share/CodeSourcery/bin #Adds gcc path
set -x NODE_PATH $NODE_PATH /usr/lib/node_modules
