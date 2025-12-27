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

# GPG TTY configuration (required for signing)
set -x GPG_TTY (tty)

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

# VS Code shell integration
# The integration script requires TERM_PROGRAM=vscode, but tmux overwrites it
# Save the original and temporarily restore it for loading the integration
if test "$VSCODE_TERM_PROGRAM" = "vscode"; and not set -q VSCODE_SHELL_INTEGRATION
    # Find the VS Code binary
    set -l vscode_bin ""

    if test "$__CFBundleIdentifier" = "com.microsoft.VSCodeInsiders"
        if test -x "/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code"
            set vscode_bin "/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code"
        end
    end

    if test -z "$vscode_bin"; and type -q code
        set vscode_bin (which code)
    end

    # Source the integration if we found a binary
    if test -n "$vscode_bin"
        set -l integration_path ($vscode_bin --locate-shell-integration-path fish 2>/dev/null)
        if test -n "$integration_path" -a -f "$integration_path"
            # Temporarily set TERM_PROGRAM for the integration script's check
            set -l original_term_program $TERM_PROGRAM
            set -gx TERM_PROGRAM vscode
            source "$integration_path"
            set -gx TERM_PROGRAM $original_term_program
        end
    end
end
