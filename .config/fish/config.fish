# Application specific
. ~/.config/fish/config.shortcuts
# . ~/.config/fish/config.prompt
. ~/.config/fish/config.git
. ~/.config/fish/config.vim

# Welcome Message
set fish_greeting ""

# Exports
set -x LC_ALL en_US.UTF-8
set -x LANG en_US.UTF-8
set -x LANGUAGE en_US.UTF-8

set -x FZF_DEFAULT_COMMAND 'ag --hidden --ignore .git -g ""'

# The next line adds the Homebrew environment
eval (/opt/homebrew/bin/brew shellenv)

# Activate mise environment
/opt/homebrew/bin/mise activate fish | source

# The next line updates PATH for the Google Cloud SDK.
# if [ -f '/usr/local/google-cloud-sdk/path.fish.inc' ]; . '/usr/local/google-cloud-sdk/path.fish.inc'; end
set gcloud_path (mise which gcloud)
if test -n "$gcloud_path"
  set source_file (dirname (dirname $gcloud_path))/path.fish.inc
  if test -f $source_file
    source $source_file
  end
end
