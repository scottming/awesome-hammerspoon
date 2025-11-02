hs.hotkey.alertDuration = 0
hs.hints.showTitleThresh = 0
hs.window.animationDuration = 0

-- Configuration loading
local function loadConfig()
	local customConfigPath = hs.fs.pathToAbsolute(os.getenv("HOME") .. "/.config/hammerspoon/private/config.lua")
	local privateConfigPath = hs.fs.pathToAbsolute(hs.configdir .. "/private/config.lua")

	if customConfigPath then
		print("Loading custom config")
		dofile(customConfigPath)
		if privateConfigPath then
			hs.alert(
				"You have config in both .config/hammerspoon and .hammerspoon/private.\nThe .config/hammerspoon one will be used."
			)
		end
	elseif privateConfigPath then
		hs.fs.mkdir(hs.configdir .. "/private")
		require("private/config")
	end
end

-- Utility functions
local function isValidKey(keys)
	return keys and #keys >= 2 and string.len(keys[2]) > 0
end

-- Modal environment factory
local function createModal(name, bindings, config)
	config = config or {}
	spoon.ModalMgr:new(name)
	local modal = spoon.ModalMgr.modal_list[name]

	-- Default exit bindings
	local exitBindings = {
		{
			key = "escape",
			desc = "Deactivate " .. name,
			action = function()
				spoon.ModalMgr:deactivate({ name })
			end,
		},
		{
			key = "Q",
			desc = "Deactivate " .. name,
			action = function()
				spoon.ModalMgr:deactivate({ name })
			end,
		},
		{
			key = "tab",
			desc = "Toggle Cheatsheet",
			action = function()
				spoon.ModalMgr:toggleCheatsheet()
			end,
		},
	}

	-- Bind all keys
	local allBindings = {}
	for _, binding in ipairs(exitBindings) do
		table.insert(allBindings, binding)
	end
	for _, binding in ipairs(bindings) do
		table.insert(allBindings, binding)
	end

	for _, binding in ipairs(allBindings) do
		local modifiers = binding.modifiers or ""
		modal:bind(modifiers, binding.key, binding.desc, binding.action, binding.onKeyDown, binding.onKeyUp)
	end

	return modal
end

-- Application launcher factory
local function createAppLauncher(appConfig)
	return function()
		if appConfig.id then
			local name = hs.application.nameForBundleID(appConfig.id)
			if name then
				hs.application.launchOrFocusByBundleID(appConfig.id)
			end
		elseif appConfig.name then
			hs.application.launchOrFocus(appConfig.name)
		end
		spoon.ModalMgr:deactivate({ "appM" })
	end
end

-- Window management action factory
local function createWindowAction(action, direction)
	return function()
		if action == "move" then
			spoon.WinWin:stepMove(direction)
		elseif action == "resize" then
			spoon.WinWin:stepResize(direction)
		elseif action == "layout" then
			spoon.WinWin:stash()
			spoon.WinWin:moveAndResize(direction)
		elseif action == "screen" then
			spoon.WinWin:stash()
			spoon.WinWin:moveToScreen(direction)
		else
			spoon.WinWin[action](spoon.WinWin)
		end
	end
end

-- Countdown action factory
local function createCountdownAction(minutes)
	return function()
		spoon.CountDown:startFor(minutes)
		spoon.ModalMgr:deactivate({ "countdownM" })
	end
end

-- Custom window layout factory
local function createCustomLayoutAction(xRatio, yRatio, widthRatio, heightRatio)
	return function()
		local win = hs.window.focusedWindow()
		if win and win:isStandard() then
			spoon.WinWin:stash() -- Only stash if we have a valid window
			local screen = win:screen()
			local frame = screen:frame()
			local newFrame = {
				x = frame.x + frame.w * xRatio,
				y = frame.y + frame.h * yRatio,
				w = frame.w * widthRatio,
				h = frame.h * heightRatio,
			}
			win:setFrame(newFrame)
		end
	end
end

-- Load configuration
loadConfig()

-- Load spoons
hs.loadSpoon("ModalMgr")
for _, spoonName in pairs(hspoon_list or {}) do
	hs.loadSpoon(spoonName)
end

-- Global hotkeys configuration
local globalHotkeys = {
	{
		keys = hsreload_keys or { { "cmd", "shift", "ctrl" }, "R" },
		desc = "Reload Configuration",
		action = hs.reload,
	},
	{
		keys = hswhints_keys or { "alt", "tab" },
		desc = "Show Window Hints",
		action = function()
			spoon.ModalMgr:deactivateAll()
			hs.hints.windowHints()
		end,
	},
	{
		keys = hstype_keys or { "alt", "V" },
		desc = "Type Browser Link",
		action = function()
			local browsers = {
				{
					id = "com.apple.Safari",
					script = 'tell application "Safari" to get {URL, name} of current tab of window 1',
				},
				{
					id = "com.google.Chrome",
					script = 'tell application "Google Chrome" to get {URL, title} of active tab of window 1',
				},
			}

			for _, browser in ipairs(browsers) do
				local running = hs.application.applicationsForBundleID(browser.id)
				if #running > 0 then
					local stat, data = hs.applescript(browser.script)
					if stat then
						hs.eventtap.keyStrokes("[" .. data[2] .. "](" .. data[1] .. ")")
						return
					end
				end
			end
		end,
	},
}

-- Bind global hotkeys
for _, hotkey in ipairs(globalHotkeys) do
	if isValidKey(hotkey.keys) then
		spoon.ModalMgr.supervisor:bind(hotkey.keys[1], hotkey.keys[2], hotkey.desc, hotkey.action)
	end
end

-- Application modal configuration
local function setupAppModal()
	local appBindings = {}

	for _, appConfig in ipairs(hsapp_list or {}) do
		table.insert(appBindings, {
			key = appConfig.key,
			desc = appConfig.name or hs.application.nameForBundleID(appConfig.id) or "Unknown App",
			action = createAppLauncher(appConfig),
		})
	end

	createModal("appM", appBindings)

	local keys = hsappM_keys or { "alt", "A" }
	if isValidKey(keys) then
		spoon.ModalMgr.supervisor:bind(keys[1], keys[2], "Enter AppM Environment", function()
			spoon.ModalMgr:deactivateAll()
			spoon.ModalMgr:activate({ "appM" }, "#FFBD2E", false)
		end)
	end
end

-- Countdown modal configuration
local function setupCountdownModal()
	if not spoon.CountDown then
		return
	end

	local countdownBindings = {
		{ key = "0", desc = "5 Minutes Countdown", action = createCountdownAction(5) },
		{ key = "return", desc = "25 Minutes Countdown", action = createCountdownAction(25) },
		{
			key = "space",
			desc = "Pause/Resume CountDown",
			action = function()
				spoon.CountDown:pauseOrResume()
				spoon.ModalMgr:deactivate({ "countdownM" })
			end,
		},
	}

	-- Add 10-90 minute options
	for i = 1, 9 do
		table.insert(countdownBindings, {
			key = tostring(i),
			desc = string.format("%s Minutes Countdown", 10 * i),
			action = createCountdownAction(10 * i),
		})
	end

	createModal("countdownM", countdownBindings)
end

-- Window management modal configuration
local function setupWindowModal()
	if not spoon.WinWin then
		return
	end

	local windowBindings = {
		-- Movement
		{
			key = "S",
			desc = "Move Leftward",
			action = createWindowAction("move", "left"),
			onKeyUp = createWindowAction("move", "left"),
		},
		{
			key = "F",
			desc = "Move Rightward",
			action = createWindowAction("move", "right"),
			onKeyUp = createWindowAction("move", "right"),
		},
		{
			key = "E",
			desc = "Move Upward",
			action = createWindowAction("move", "up"),
			onKeyUp = createWindowAction("move", "up"),
		},
		{
			key = "D",
			desc = "Move Downward",
			action = createWindowAction("move", "down"),
			onKeyUp = createWindowAction("move", "down"),
		},

		-- Layout
		{ key = "H", desc = "Lefthalf of Screen", action = createWindowAction("layout", "halfleft") },
		{ key = "L", desc = "Righthalf of Screen", action = createWindowAction("layout", "halfright") },
		{ key = "K", desc = "Uphalf of Screen", action = createWindowAction("layout", "halfup") },
		{ key = "J", desc = "Downhalf of Screen", action = createWindowAction("layout", "halfdown") },
		{ key = "Z", desc = "Left Two Thirds", action = createCustomLayoutAction(0, 0, 2 / 3, 1) },
		{ key = "/", desc = "Right One Third", action = createCustomLayoutAction(2 / 3, 0, 1 / 3, 1) },

		-- Corners
		{ key = "Y", desc = "NorthWest Corner", action = createWindowAction("layout", "cornerNW") },
		{ key = "O", desc = "NorthEast Corner", action = createWindowAction("layout", "cornerNE") },
		{ key = "U", desc = "SouthWest Corner", action = createWindowAction("layout", "cornerSW") },
		{ key = "I", desc = "SouthEast Corner", action = createWindowAction("layout", "cornerSE") },

		-- Special layouts
		{ key = "G", desc = "Fullscreen", action = createWindowAction("layout", "fullscreen") },
		{ key = "C", desc = "Center Window", action = createWindowAction("layout", "center") },

		-- Resize
		{
			key = "=",
			desc = "Stretch Outward",
			action = createWindowAction("expand"),
			onKeyUp = createWindowAction("expand"),
		},
		{
			key = "-",
			desc = "Shrink Inward",
			action = createWindowAction("shrink"),
			onKeyUp = createWindowAction("shrink"),
		},

		-- Resize with shift
		{
			key = "H",
			modifiers = "shift",
			desc = "Resize Left",
			action = createWindowAction("resize", "left"),
			onKeyUp = createWindowAction("resize", "left"),
		},
		{
			key = "L",
			modifiers = "shift",
			desc = "Resize Right",
			action = createWindowAction("resize", "right"),
			onKeyUp = createWindowAction("resize", "right"),
		},
		{
			key = "K",
			modifiers = "shift",
			desc = "Resize Up",
			action = createWindowAction("resize", "up"),
			onKeyUp = createWindowAction("resize", "up"),
		},
		{
			key = "J",
			modifiers = "shift",
			desc = "Resize Down",
			action = createWindowAction("resize", "down"),
			onKeyUp = createWindowAction("resize", "down"),
		},

		-- Screen movement
		{ key = "left", desc = "Move to Left Monitor", action = createWindowAction("screen", "left") },
		{ key = "right", desc = "Move to Right Monitor", action = createWindowAction("screen", "right") },
		{ key = "up", desc = "Move to Above Monitor", action = createWindowAction("screen", "up") },
		{ key = "down", desc = "Move to Below Monitor", action = createWindowAction("screen", "down") },
		{ key = "space", desc = "Move to Next Monitor", action = createWindowAction("screen", "next") },

		-- Undo/Redo
		{ key = "[", desc = "Undo Window Manipulation", action = createWindowAction("undo") },
		{ key = "]", desc = "Redo Window Manipulation", action = createWindowAction("redo") },
		{ key = "`", desc = "Center Cursor", action = createWindowAction("centerCursor") },
	}

	createModal("resizeM", windowBindings)

	local keys = hsresizeM_keys or { "alt", "R" }
	if isValidKey(keys) then
		spoon.ModalMgr.supervisor:bind(keys[1], keys[2], "Enter resizeM Environment", function()
			spoon.ModalMgr:deactivateAll()
			spoon.ModalMgr:activate({ "resizeM" }, "#B22222")
		end)
	end
end

-- Initialize all modals
setupAppModal()
setupCountdownModal()
setupWindowModal()

-- Start modal manager
spoon.ModalMgr.supervisor:enter()
