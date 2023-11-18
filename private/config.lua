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
	{ key = "f", name = "Finder" },
	{ key = "3", name = "iTerm" },
	{ key = "k", name = "Slack" },
	{ key = "V", name = "Visual Studio Code" },
	{ key = "E", name = "EuDic" },
	{ key = "S", name = "Sublime Text" },
	{ key = "C", id = "com.google.Chrome" },
	{ key = "W", name = "WeChat" },
	{ key = "I", name = "IntelliJ IDEA" },
	-- { key = "B", name = "Bear" },
	{ key = "N", name = "Logseq" },
	{ key = "G", name = "Grammarly Editor" },
	{ key = "T", name = "DataGrip" },
	{ key = "P", name = "PDF Expert" },
	{ key = "L", name = "DeepL" },
	{ key = "D", name = "DEVONthink 3" },
	-- {key = "M", name = "Postman"},
	{ key = "o", name = "Poe" },
	{ key = "B", name = "Bear" },
	-- { key = "O", name = "Logseq" },
}

-- Modal supervisor keybinding, which can be used to temporarily disable ALL modal environments.
hsupervisor_keys = { { "cmd", "shift", "ctrl" }, "Q" }

-- Reload Hammerspoon configuration
hsreload_keys = { { "cmd", "ctrl", "alt" }, "R" }

-- Toggle help panel of this configuration.
hshelp_keys = { { "alt", "shift" }, "/" }

----------------------------------------------------------------------------------------------------
-- Those keybindings below could be disabled by setting to {"", ""} or {{}, ""}

-- Window hints keybinding: Focuse to any window you want
-- hswhints_keys = {"alt", "tab"}
hswhints_keys = { "", "" }

-- appM environment keybinding: Application Launcher
hsappM_keys = { "alt", "A" }

-- resizeM environment keybinding: Windows manipulation
hsresizeM_keys = { "alt", "R" }

show_resize_tips = false

-- bind app
local app_map = {
	["1"] = "Alacritty",
	["2"] = "Dash",
	--[[ ["3"] = "iTerm", ]]
	["3"] = "Logseq",
}

local function bind_app()
	for key, app in pairs(app_map) do
		hs.hotkey.bind({ "alt" }, key, function()
			hs.application.open(app)
		end)
	end
end

-- auto switch input method

local function Chinese()
	return "com.sogou.inputmethod.sogou.pinyin"
end

local function English()
	return "com.apple.keylayout.US"
end

local appWithInputMethods = {
	{ "Alfred", English },
	{ "WeChat", Chinese },
	{ "Code", English },
	{ "Google Chrome", English },
	{ "Sublime Text", English },
	{ "Alacritty", English },
}

-- https://gist.github.com/ibreathebsb/65fae9d742c5ebdb409960bceaf934de
local function maybeUpdateFocusesInputMethod()
	-- local ime = English()
	local ime
	local focusedApp = hs.window.focusedWindow():application():name()
	for _, app in pairs(appWithInputMethods) do
		local appName = app[1]
		local expectedIme = app[2]

		if focusedApp == appName then
			ime = expectedIme()
			break
		end
	end

	if ime ~= nil and hs.keycodes.currentSourceID() ~= ime then
		hs.keycodes.currentSourceID(ime)
	end
end

local function applicationWatcher(_appName, eventType, appObject)
	if eventType == hs.application.watcher.activated or eventType == hs.application.watcher.launched then
		maybeUpdateFocusesInputMethod()
	end
end

appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()

hs.hotkey.bind({ "ctrl", "cmd" }, ".", function()
	hs.alert.show(
		"App path:        "
			.. hs.window.focusedWindow():application():path()
			.. "\n"
			.. "App name:      "
			.. hs.window.focusedWindow():application():name()
			.. "\n"
			.. "IM source id:  "
			.. hs.keycodes.currentSourceID()
	)
end)

bind_app()
hs.alert.show("Hammerspoon, at your service", 3)
