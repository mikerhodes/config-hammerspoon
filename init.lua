
-- Set up our logging
hs.logger.defaultLogLevel = 'info'
logger = hs.logger.new('hs')

-- Set up overlays for inactive windows
-- hs.window.highlight.ui.overlay=true
-- hs.window.highlight.start()
-- hs.window.highlight.ui.overlayColor = {0.1,0.1,0.1,0.2}

-- Set up a config reload hotkey
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
    hs.alert 'Reloading config'
    hs.reload()
end)

local DELL_27_SCREEN_ID = 'DELL U2713HM'
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
for i = 1, #v do
  app_resize_functions[v[i]] = {
    ["27"] = pw(1367, 22, 1193, 685),  -- top right
    ["24"] = pw(727, 22, 1193, 685),
    ["11"] = fs()
  }
end

v = { }  -- Used to be Terminal
for i = 1, #v do
  app_resize_functions[v[i]] = {
    ["27"] = pw(0, 22, 1366, 685),
    ["24"] = pw(0, 22, 1366, 685),
    ["11"] = fs()
  }
end

v = {  }  -- Used to be 'IBM Notes', 'Thunderbird'
for i = 1, #v do
  app_resize_functions[v[i]] = {
    ["27"] = pw(258, 105, 1071, 1158),  -- some odd least-ugly placement
    ["24"] = pw(258, 26, 1071, 1158),
    ["11"] = fs()
  }
end

v = { 'OmniFocus' }
for i = 1, #v do
  app_resize_functions[v[i]] = {
    ["27"] = pw(2000, 0, 560, 1440),  -- some odd least-ugly placement
    ["24"] = fs(),
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
'Slack',
'SourceTree',
'Terminal',
'Google Hangouts',
'Things',
'Code',
'Messages',
'WhatsApp',
'GitUp',
'IBM Notes',
'Thunderbird' }
for i = 1, #v do
  app_resize_functions[v[i]] = {
    ["27"] = pw(0, 0, 2000, 1440),  -- top right
    ["24"] = fs(),
    ["11"] = fs()
  }
end

function position()
  local t = {
    [2560] = "27",
    [1920] = "24",
    [1366] = "11"
  }
  local monitorLayout = t[hs.screen.mainScreen():frame().w] or '11'

  for name, resizeFunctions in pairs(app_resize_functions) do
    local app = hs.application(name)
    if app then
      for _,win in ipairs(app:allWindows()) do
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

position_hotkey_timer = nil  -- global for timer, so we can cancel on exit

k = hs.hotkey.modal.new('ctrl', 'space')
function k:entered()
  local timeout = 2
  hs.alert('Position Windows', timeout)

  -- cancel any existing position_hotkey_timer
  if position_hotkey_timer then
    position_hotkey_timer:stop()
    position_hotkey_timer = nil
  end
  position_hotkey_timer = hs.timer.doAfter(timeout, function()
    k:exit()
  end)
end
function k:exited()
  -- we're exiting, clear the timer that auto-exits
  if position_hotkey_timer then
    position_hotkey_timer:stop()
    position_hotkey_timer = nil
    hs.alert.closeAll()
  end
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

k:bind('', '4', function()
  local win = hs.window.focusedWindow()
  local screen = win:screen()
  local max = screen:frame()
  position_window(
    win,
    max.x,
    max.y,
    max.w * 0.66,
    max.h
  )
  k:exit();
end)

k:bind('', '5', function()
  local win = hs.window.focusedWindow()
  local screen = win:screen()
  local max = screen:frame()
  position_window(
    win,
    max.x + (max.w * 0.66),
    max.y,
    max.w * 0.34,
    max.h
  )
  k:exit();
end)

--[[
    Helper functions
--]]

function position_window(win, x, y, w, h, screen_id)
    local f = win:frame()
    f.x = x
    f.y = y
    f.w = w
    f.h = h
    win:setFrame(f)
end

function full_screen(win, screen_id)
    local screen = win:screen()
    local max = screen:frame()
    local f = win:frame()
    f.x = max.x
    f.y = max.y
    f.w = max.w
    f.h = max.h
    win:setFrame(f)
end

