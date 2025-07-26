-- private/config.lua - Declarative Configuration

-- Core configuration
local config = {
	spoons = { "CountDown", "WinWin" },

	hotkeys = {
		supervisor = { { "cmd", "shift", "ctrl" }, "Q" },
		reload = { { "cmd", "ctrl", "alt" }, "R" },
		help = { { "alt", "shift" }, "/" },
		windowHints = { "", "" }, -- Disabled
		appModal = { "alt", "A" },
		resizeModal = { "alt", "R" },
	},

	apps = {
		{ key = "f", name = "Finder" },
		{ key = "k", name = "Slack" },
		{ key = "V", name = "Cursor" },
		{ key = "E", name = "EuDic" },
		{ key = "S", name = "Sublime Text" },
		{ key = "C", id = "com.google.Chrome" },
		{ key = "A", name = "Brave Browser" },
		{ key = "W", name = "Ghostty" },
		{ key = "I", name = "IntelliJ IDEA" },
		{ key = "G", name = "ChatGPt" },
		{ key = "T", name = "DataGrip" },
		{ key = "P", name = "PDF Expert" },
		{ key = "L", name = "Obsidian" },
		{ key = "O", name = "Poe" },
		{ key = "D", name = "DEVONthink 3" },
		{ key = "B", name = "Bear" },
	},

	quickApps = {
		["1"] = "Alacritty",
		["2"] = "Dash",
		["3"] = "Logseq",
	},

	inputMethods = {
		chinese = "com.sogou.inputmethod.sogou.pinyin",
		english = "com.apple.keylayout.US",

		mapping = {
			WeChat = "chinese",
			Obsidian = "chinese",
			Bear = "chinese",
			Telegram = "chinese",
			Ghostty = "english",
			Alfred = "english",
			Code = "english",
			Cursor = "english",
			["Google Chrome"] = "english",
			["Sublime Text"] = "english",
			Alacritty = "english",
			Dash = "english",
		},
	},

	features = {
		showResizeTips = false,
		autoInputMethod = true,
		debugInfo = true,
	},
}

-- Export configuration to global scope
hspoon_list = config.spoons
hsapp_list = config.apps
hsupervisor_keys = config.hotkeys.supervisor
hsreload_keys = config.hotkeys.reload
hshelp_keys = config.hotkeys.help
hswhints_keys = config.hotkeys.windowHints
hsappM_keys = config.hotkeys.appModal
hsresizeM_keys = config.hotkeys.resizeModal
show_resize_tips = config.features.showResizeTips

-- Application management
local function bindQuickApps(appMap)
	for key, appName in pairs(appMap) do
		hs.hotkey.bind({ "alt" }, key, function()
			hs.application.open(appName)
		end)
	end
end

-- Input method management
local function getInputMethodConfig()
	return {
		chinese = config.inputMethods.chinese,
		english = config.inputMethods.english,
		getForApp = function(appName)
			local method = config.inputMethods.mapping[appName]
			return method and config.inputMethods[method]
		end,
	}
end

local function createInputMethodSwitcher(imConfig)
	return function()
		local focusedWindow = hs.window.focusedWindow()
		if not focusedWindow then
			return
		end

		local appName = focusedWindow:application():name()
		local targetIM = imConfig.getForApp(appName)

		if targetIM and hs.keycodes.currentSourceID() ~= targetIM then
			hs.keycodes.currentSourceID(targetIM)
		end
	end
end

local function createAppWatcher(switcherFn)
	return function(appName, eventType, appObject)
		if eventType == hs.application.watcher.activated or eventType == hs.application.watcher.launched then
			switcherFn()
		end
	end
end

-- Debug utilities
local function createDebugReporter()
	return function()
		local focusedWindow = hs.window.focusedWindow()
		if not focusedWindow then
			return
		end

		local app = focusedWindow:application()
		local message = string.format(
			"App path:        %s\nApp name:      %s\nIM source id:  %s",
			app:path(),
			app:name(),
			hs.keycodes.currentSourceID()
		)
		hs.alert.show(message)
	end
end

-- Initialize features
local function initializeFeatures()
	-- Quick app bindings
	bindQuickApps(config.quickApps)

	-- Input method auto-switching
	if config.features.autoInputMethod then
		local imConfig = getInputMethodConfig()
		local switchInputMethod = createInputMethodSwitcher(imConfig)
		local watcherCallback = createAppWatcher(switchInputMethod)

		appWatcher = hs.application.watcher.new(watcherCallback)
		appWatcher:start()
	end

	-- Debug info hotkey
	if config.features.debugInfo then
		hs.hotkey.bind({ "ctrl", "cmd" }, ".", createDebugReporter())
	end
end

-- Application entry point
local function main()
	initializeFeatures()
	hs.alert.show("Hammerspoon, at your service", 3)
end

-- Execute main function
main()
