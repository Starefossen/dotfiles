function fish_user_key_bindings
  fish_vi_key_bindings
  bind -M insert -m default jj backward-char force-repaint
end

set -g fish_key_bindings fish_user_key_bindings
set -g __fish_vi_mode 1
