#!/usr/bin/env fish

function kioskmode -d "Open URL in kiosk mode"
  command /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --kiosk --app=$argv[1]
end
