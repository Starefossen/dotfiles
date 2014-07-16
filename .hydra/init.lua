-- refers to grid.lua in this directory, taken from the Hydra wiki: https://github.com/sdegutis/hydra/wiki/Useful-Hydra-libraries
dofile(package.searchpath("grid", package.path))

hydra.alert "Hydra, at your service."

pathwatcher.new(os.getenv("HOME") .. "/.hydra/", hydra.reload):start()
autolaunch.set(true)

menu.show(function()
    return {
      {title = "About Hydra", fn = hydra.showabout},
      {title = "-"},
      {title = "Quit", fn = os.exit},
    }
end)

local mash = {"cmd", "alt", "ctrl"}
local mashshift = {"cmd", "alt", "shift"}

local function opendictionary()
  hydra.alert("Lexicon, at your service.", 0.75)
  application.launchorfocus("Dictionary")
end

hotkey.bind(mash, 'D', opendictionary)

hotkey.bind(mash, ';', function() ext.grid.snap(window.focusedwindow()) end)
hotkey.bind(mash, "'", function() fnutils.map(window.visiblewindows(), ext.grid.snap) end)

hotkey.bind(mash, '=', function() ext.grid.adjustwidth( 1) end)
hotkey.bind(mash, '-', function() ext.grid.adjustwidth(-1) end)

hotkey.bind(mashshift, 'H', function() window.focusedwindow():focuswindow_west() end)
hotkey.bind(mashshift, 'L', function() window.focusedwindow():focuswindow_east() end)
hotkey.bind(mashshift, 'K', function() window.focusedwindow():focuswindow_north() end)
hotkey.bind(mashshift, 'J', function() window.focusedwindow():focuswindow_south() end)

hotkey.bind(mash, 'M', ext.grid.maximize_window)

hotkey.bind(mash, 'N', ext.grid.pushwindow_nextscreen)
hotkey.bind(mash, 'P', ext.grid.pushwindow_prevscreen)

hotkey.bind(mash, 'J', ext.grid.pushwindow_down)
hotkey.bind(mash, 'K', ext.grid.pushwindow_up)
hotkey.bind(mash, 'H', ext.grid.pushwindow_left)
hotkey.bind(mash, 'L', ext.grid.pushwindow_right)

hotkey.bind(mash, 'U', ext.grid.resizewindow_taller)
hotkey.bind(mash, 'O', ext.grid.resizewindow_wider)
hotkey.bind(mash, 'I', ext.grid.resizewindow_thinner)

hotkey.bind(mash, 'X', logger.show)
hotkey.bind(mash, "R", repl.open)

function checkforupdates()
  -- I'm fine with making this a global; then I can call it in the REPL if I want.
  updates.check(function(hasone)
      if hasone then
        notify.show("Hydra update available", "Go download it!", "Click here to see the release notes.", "hasupdate")
      end
  end)
end
notify.register("hasupdate", function() os.execute("open " .. updates.changelogurl) end)

checkforupdates()

timer.new(timer.days(1), checkforupdates):start()
