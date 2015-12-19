
-- Set up our logging
hs.logger.defaultLogLevel = 'info'
logger = hs.logger.new('hs')

-- Set up a config reload hotkey
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
    hs.alert 'Reloading config'
    hs.reload()
end)

local DELL_27_SCREEN_ID = ''
local DELL_24_SCREEN_ID = 'DELL U2415'
local LAPTOP_SCREEN_ID = 'Color LCD'

--[[
   pw() and fs() return functions to resize windows to a given size.
   The returned functions are called entered into app_resize_functions
   to be later called during automatic window positioning.
--]]

-- Return a function to resize an window to a given position and size.
function pw(x, y, w, h, outer_screen_id)
  return function(win, screen_id)
    if not outer_screen_id then
      screen_id = outer_screen_id
    end
    position_window(win, x, y, w, h, screen_id)
  end
end

-- Return a function to resize a window to fill the screen.
function fs(outer_screen_id)
  return function(win, screen_id)
    if not outer_screen_id then
      screen_id = outer_screen_id
    end
    full_screen(win, screen_id)
  end
end

--[[
   Each app to resize has an entry in this dictionary, keyed by application
   name. The entry consists of a resizing function for the windows of the
   application. The entry has three properties, each containing a resizing
   function. The resizing function is run on an application's windows during
   position().
    - 27: position on 27" monitor
    - 24: position on 24" monitor
    - 11: position on 11" screen (laptop)
--]]

local app_resize_functions = {}

v = { 'LimeChat', '1Password' }
for i = 1, #v do  -- #v is the size of v for lists.
  app_resize_functions[v[i]] = {
    ["27"] = pw(1367, 22, 1193, 685),  -- top right
    ["24"] = pw(727, 22, 1193, 685),
    ["11"] = fs()
  }
end

v = {
'Sublime Text',
'IntelliJ IDEA',
'Xcode',
'Nightly',
'Aurora',
'Firefox',
'FirefoxDeveloperEdition',
'Google Chrome',
'Evernote',
'Slack' }
for i = 1, #v do  -- #v is the size of v for lists.
  app_resize_functions[v[i]] = {
    ["27"] = pw(258, 105, 1904, 1158),  -- top right
    ["24"] = fs(),
    ["11"] = fs()
  }
end

function position()
  local screenWidth = hs.screen.mainScreen():frame().w
  local t = {
    [2560] = "27",
    [1920] = "24",
    [1366] = "11"
  }
  local monitorLayout = t[screenWidth] or '11'
  logger:i(string.format("Monitor Layout: %s", monitorLayout))

  -- runningApplications = hs.application.runningApplications()

  for name, resizeFunctions in pairs(app_resize_functions) do
    local app = hs.application(name)
    if app then
      logger:i(string.format("Found app: %s", app:title()))
      for _,win in pairs(app:allWindows()) do
        logger:i(string.format("Found windows: %s", win:title()))
        resizeFunctions[monitorLayout](win)
      end
    end
  end

end

--[[
    Here we're binding ctrl-space to start a chained keyboard shortcut.

    escape => leave mode
    0 => auto layout
    1 => left half
    2 => right half
    3 => full screen
--]]

k = hs.hotkey.modal.new('ctrl', 'space')
function k:entered()
  hs.alert'Position Windows'
  -- hs.timer.doAfter(2, function()
  --   hs.alert'Cancel mode'
  --   k:exit()
  -- end)
end

k:bind('', 'escape', function()
  hs.alert'Cancel mode'
  k:exit()
end)

k:bind('', '0', nil, function()
  position()
  k:exit()
end)

k:bind('', '1', function()
  local win = hs.window.focusedWindow()
  local screen = win:screen()
  local max = screen:frame()
  position_window(
    win,
    max.x,
    max.y,
    max.w / 2,
    max.h
  )
  k:exit();
end)

k:bind('', '2', function()
  local win = hs.window.focusedWindow()
  local screen = win:screen()
  local max = screen:frame()
  position_window(
    win,
    max.x + (max.w / 2),
    max.y,
    max.w / 2,
    max.h
  )
  k:exit();
end)

k:bind('', '3', function()
  local win = hs.window.focusedWindow()
  full_screen(win)
  k:exit();
end)

--[[
    Helper functions
--]]

function position_window(win, x, y, w, h, screen_id)
    logger:i(string.format("%s => %f, %f, %f, %f", win:title(), x, y, w, h))
    local f = win:frame()
    f.x = x
    f.y = y
    f.w = w
    f.h = h
    win:setFrame(f)
end

function full_screen(win, screen_id)
    logger:i(string.format("%s => full screen", win:title(), x, y, w, h))
    local screen = win:screen()
    local max = screen:frame()
    local f = win:frame()
    f.x = max.x
    f.y = max.y
    f.w = max.w
    f.h = max.h
    win:setFrame(f)
end

