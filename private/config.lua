-- private/config.lua
-- Specify Spoons which will be loaded
hspoon_list = {
    -- "AClock",
    -- "BingDaily",
    -- "Calendar",
    -- "CircleClock",
    -- "ClipShow",
    "CountDown",
    -- "FnMate",
    -- "HCalendar",
    -- "HSaria2",
    -- "HSearch",
    -- "KSheet",
    -- "SpeedMenu",
    -- "TimeFlow",
    -- "UnsplashZ",
    "WinWin",
}

-- appM environment keybindings. Bundle `id` is prefered, but application `name` will be ok.
hsapp_list = {
    {key = 'f', name = 'Finder'},
    {key = '1', name = 'iTerm'},
    {key = "P", name = "PyCharm"},
    {key = "V", name = "Visual Studio Code"},
    {key = "E", name = "EuDic"},
    {key = "S", name = "Sublime Text"},
    {key = "C", id = "com.google.Chrome"},
    {key = "M", name = "Emacs"},
    {key = "W", name = 'WeChat'},
    {key = "I", name = "IntelliJ IDEA"},
    {key = 'o', name = 'Firefox'},
    {key = "B", name = "Bear"},
    {key = "G", name = "GraphiQL"},
    -- {key = 'A', name = 'Atom'},
    -- {key = "M", name = "PyCharm"},
    -- {key = "M", name = "TextMate"},
    -- {key = "P", name = "PDF Expert"},
    -- {key = 'y', name = 'System Preferences'},
    -- {key = 'g', name = 'GoLand'},
}

-- Modal supervisor keybinding, which can be used to temporarily disable ALL modal environments.
hsupervisor_keys = {{"cmd", "shift", "ctrl"}, "Q"}

-- Reload Hammerspoon configuration
hsreload_keys = {{"cmd", "ctrl", "alt"}, "R"}

-- Toggle help panel of this configuration.
hshelp_keys = {{"alt", "shift"}, "/"}

----------------------------------------------------------------------------------------------------
-- Those keybindings below could be disabled by setting to {"", ""} or {{}, ""}

-- Window hints keybinding: Focuse to any window you want
-- hswhints_keys = {"alt", "tab"}
hswhints_keys = {"", ""}

-- appM environment keybinding: Application Launcher
hsappM_keys = {"alt", "A"}

-- resizeM environment keybinding: Windows manipulation
hsresizeM_keys = {"alt", "R"}

show_resize_tips = false

-- bind app
local app_map = {
    ["1"] = "iTerm",
    ["2"] = "Google Chrome",
    ["3"] = "PyCharm",
    ["4"] = "Emacs",
}

local function bind_app()
    for key, app in pairs(app_map) do
        hs.hotkey.bind({"alt"}, key,
            function()
                hs.application.open(app)
            end
        )
    end
end


-- auto switch input method

local function Chinese()
  hs.keycodes.currentSourceID("com.sogou.inputmethod.sogou.pinyin")
end

local function English()
  hs.keycodes.currentSourceID("com.apple.keylayout.US")
end

local function set_app_input_method(app_name, set_input_method_function, event)
  event = event or hs.window.filter.windowFocused

  hs.window.filter.new(app_name)
    :subscribe(event, function()
                 set_input_method_function()
              end)
end

set_app_input_method('Alfred', English, hs.window.filter.windowCreated)
set_app_input_method('Emacs', English)
-- set_app_input_method('iTerm2', English)
-- set_app_input_method('Code', English)
set_app_input_method('Google Chrome', English)
set_app_input_method('Sublime Text', English)
set_app_input_method('Postico', English)
set_app_input_method('IntelliJ IDEA', English)
set_app_input_method('PyCharm', English)
set_app_input_method('GoLand', English)


hs.hotkey.bind({'ctrl', 'cmd'}, ".", function()
          hs.alert.show("App path:        "
                ..hs.window.focusedWindow():application():path()
                .."\n"
                .."App name:      "
                ..hs.window.focusedWindow():application():name()
                .."\n"
                .."IM source id:  "
                ..hs.keycodes.currentSourceID())
end)


bind_app()
hs.alert.show("Hammerspoon, at your service", 3)
