#!/usr/bin/env fish

function noprompt -d "Disable the prompt"
  function fish_prompt
    echo "> "
  end
end
