--- === WinWin ===
---
--- Windows manipulation
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/WinWin.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/WinWin.spoon.zip)

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "WinWin"
obj.version = "1.0"
obj.author = "ashfinal <ashfinal@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Windows manipulation history. Only the last operation is stored.
obj.history = {}

--- WinWin.gridparts
--- Variable
--- An integer specifying how many gridparts the screen should be divided into. Defaults to 30.
obj.gridparts = 30

--- WinWin.MAX_HISTORY
--- Variable
--- Maximum number of history items to keep. Defaults to 100.
obj.MAX_HISTORY = 100

-- Helper function: Get window context with screen information
local function getWindowContext(gridparts)
	local win = hs.window.focusedWindow()
	if not win then
		hs.alert.show("No focused window!")
		return nil
	end

	local screen = win:screen()
	local frame = screen:fullFrame()

	return {
		window = win,
		screen = screen,
		frame = frame,
		stepW = frame.w / gridparts,
		stepH = frame.h / gridparts,
	}
end

-- Helper function: Execute window operation with accessibility fix (for Grammarly compatibility)
local function withAccessibilityFix(win, operation)
	local axApp = hs.axuielement.applicationElement(win:application())
	local wasEnhanced = axApp.AXEnhancedUserInterface

	if wasEnhanced then
		axApp.AXEnhancedUserInterface = false
	end

	operation()

	if wasEnhanced then
		axApp.AXEnhancedUserInterface = true
	end
end

--- WinWin:stepMove(direction)
--- Method
--- Move the focused window in the `direction` by on step. The step scale equals to the width/height of one gridpart.
---
--- Parameters:
---  * direction - A string specifying the direction, valid strings are: `left`, `right`, `up`, `down`.
function obj:stepMove(direction)
	local ctx = getWindowContext(obj.gridparts)
	if not ctx then
		return
	end

	local wtopleft = ctx.window:topLeft()
	if direction == "left" then
		ctx.window:setTopLeft({ x = wtopleft.x - ctx.stepW, y = wtopleft.y })
	elseif direction == "right" then
		ctx.window:setTopLeft({ x = wtopleft.x + ctx.stepW, y = wtopleft.y })
	elseif direction == "up" then
		ctx.window:setTopLeft({ x = wtopleft.x, y = wtopleft.y - ctx.stepH })
	elseif direction == "down" then
		ctx.window:setTopLeft({ x = wtopleft.x, y = wtopleft.y + ctx.stepH })
	end
end

--- WinWin:stepResize(direction)
--- Method
--- Resize the focused window in the `direction` by on step.
---
--- Parameters:
---  * direction - A string specifying the direction, valid strings are: `left`, `right`, `up`, `down`.
function obj:stepResize(direction)
	local ctx = getWindowContext(obj.gridparts)
	if not ctx then
		return
	end

	local wsize = ctx.window:size()
	if direction == "left" then
		ctx.window:setSize({ w = wsize.w - ctx.stepW, h = wsize.h })
	elseif direction == "right" then
		ctx.window:setSize({ w = wsize.w + ctx.stepW, h = wsize.h })
	elseif direction == "up" then
		ctx.window:setSize({ w = wsize.w, h = wsize.h - ctx.stepH })
	elseif direction == "down" then
		ctx.window:setSize({ w = wsize.w, h = wsize.h + ctx.stepH })
	end
end

--- WinWin:stash()
--- Method
--- Stash current windows's position and size.
---

local function isInHistory(windowid)
	for idx, val in ipairs(obj.history) do
		if val[1] == windowid then
			return idx
		end
	end
	return false
end

-- Helper function: Manipulate history for undo/redo operations
local function manipulateHistory(winid, mode)
	local id_idx = isInHistory(winid)
	if not id_idx then
		return nil
	end

	-- Bring recently used window id to the front if it's at max capacity
	if id_idx == obj.MAX_HISTORY then
		local tmptable = obj.history[id_idx]
		table.remove(obj.history, id_idx)
		table.insert(obj.history, 1, tmptable)
		id_idx = 1
	end

	local id_history = obj.history[id_idx][2]
	local frameIndex = (mode == "undo") and 1 or #id_history

	return id_history[frameIndex], id_history, frameIndex
end

function obj:stash()
	local cwin = hs.window.focusedWindow()
	if not cwin then
		return
	end

	local winid = cwin:id()
	local winf = cwin:frame()
	local id_idx = isInHistory(winid)

	if id_idx then
		-- Bring recently used window id up, so they wouldn't get removed because of exceeding capacity
		if id_idx == obj.MAX_HISTORY then
			local tmptable = obj.history[id_idx]
			table.remove(obj.history, id_idx)
			table.insert(obj.history, 1, tmptable)
			-- Make sure the history for each application doesn't reach the maximum
			local id_history = obj.history[1][2]
			if #id_history > obj.MAX_HISTORY then
				table.remove(id_history)
			end
			table.insert(id_history, 1, winf)
		else
			local id_history = obj.history[id_idx][2]
			if #id_history > obj.MAX_HISTORY then
				table.remove(id_history)
			end
			table.insert(id_history, 1, winf)
		end
	else
		-- Make sure the history of window id doesn't reach the maximum
		if #obj.history > obj.MAX_HISTORY then
			table.remove(obj.history)
		end
		-- Stash new window id and its first history
		local newtable = { winid, { winf } }
		table.insert(obj.history, 1, newtable)
	end
end

--- WinWin:moveAndResize(option)
--- Method
--- Move and resize the focused window.
---
--- Parameters:
---  * option - A string specifying the option, valid strings are: `halfleft`, `halfright`, `halfup`, `halfdown`, `cornerNW`, `cornerSW`, `cornerNE`, `cornerSE`, `center`, `fullscreen`, `expand`, `shrink`.

function obj:moveAndResize(option)
	local ctx = getWindowContext(obj.gridparts)
	if not ctx then
		return
	end

	withAccessibilityFix(ctx.window, function()
		local cres = ctx.frame
		local wf = ctx.window:frame()

		if option == "halfleft" then
			ctx.window:setFrame({ x = cres.x, y = cres.y, w = cres.w / 2, h = cres.h })
		elseif option == "halfright" then
			ctx.window:setFrame({ x = cres.x + cres.w / 2, y = cres.y, w = cres.w / 2, h = cres.h })
		elseif option == "halfup" then
			ctx.window:setFrame({ x = cres.x, y = cres.y, w = cres.w, h = cres.h / 2 })
		elseif option == "halfdown" then
			ctx.window:setFrame({ x = cres.x, y = cres.y + cres.h / 2, w = cres.w, h = cres.h / 2 })
		elseif option == "cornerNW" then
			ctx.window:setFrame({ x = cres.x, y = cres.y, w = cres.w / 2, h = cres.h / 2 })
		elseif option == "cornerNE" then
			ctx.window:setFrame({ x = cres.x + cres.w / 2, y = cres.y, w = cres.w / 2, h = cres.h / 2 })
		elseif option == "cornerSW" then
			ctx.window:setFrame({ x = cres.x, y = cres.y + cres.h / 2, w = cres.w / 2, h = cres.h / 2 })
		elseif option == "cornerSE" then
			ctx.window:setFrame({ x = cres.x + cres.w / 2, y = cres.y + cres.h / 2, w = cres.w / 2, h = cres.h / 2 })
		elseif option == "fullscreen" then
			ctx.window:setFrame({ x = cres.x, y = cres.y, w = cres.w, h = cres.h })
		elseif option == "center" then
			ctx.window:centerOnScreen()
		elseif option == "expand" then
			ctx.window:setFrame({
				x = wf.x - ctx.stepW,
				y = wf.y - ctx.stepH,
				w = wf.w + (ctx.stepW * 2),
				h = wf.h + (ctx.stepH * 2),
			})
		elseif option == "shrink" then
			ctx.window:setFrame({
				x = wf.x + ctx.stepW,
				y = wf.y + ctx.stepH,
				w = wf.w - (ctx.stepW * 2),
				h = wf.h - (ctx.stepH * 2),
			})
		end
	end)
end

--- WinWin:moveToScreen(direction)
--- Method
--- Move the focused window between all of the screens in the `direction`.
---
--- Parameters:
---  * direction - A string specifying the direction, valid strings are: `left`, `right`, `up`, `down`, `next`.
function obj:moveToScreen(direction)
	local ctx = getWindowContext(obj.gridparts)
	if not ctx then
		return
	end

	if direction == "up" then
		ctx.window:moveOneScreenNorth()
	elseif direction == "down" then
		ctx.window:moveOneScreenSouth()
	elseif direction == "left" then
		ctx.window:moveOneScreenWest()
	elseif direction == "right" then
		ctx.window:moveOneScreenEast()
	elseif direction == "next" then
		ctx.window:moveToScreen(ctx.screen:next())
	end
end

--- WinWin:undo()
--- Method
--- Undo the last window manipulation. Only those "moveAndResize" manipulations can be undone.
---

function obj:undo()
	local cwin = hs.window.focusedWindow()
	if not cwin then
		return
	end

	local winid = cwin:id()
	local frame, id_history, frameIndex = manipulateHistory(winid, "undo")

	if frame and id_history and frameIndex then
		cwin:setFrame(frame)
		-- Rewind the history
		table.remove(id_history, frameIndex)
		table.insert(id_history, frame)
	end
end

--- WinWin:redo()
--- Method
--- Redo the window manipulation. Only those "moveAndResize" manipulations can be undone.
---

function obj:redo()
	local cwin = hs.window.focusedWindow()
	if not cwin then
		return
	end

	local winid = cwin:id()
	local frame, id_history, frameIndex = manipulateHistory(winid, "redo")

	if frame and id_history and frameIndex then
		cwin:setFrame(frame)
		-- Play the history
		table.remove(id_history, frameIndex)
		table.insert(id_history, 1, frame)
	end
end

--- WinWin:centerCursor()
--- Method
--- Center the cursor on the focused window.
---

function obj:centerCursor()
	local cwin = hs.window.focusedWindow()
	if cwin then
		-- Center the cursor on the focused window
		local wf = cwin:frame()
		hs.mouse.setAbsolutePosition({ x = wf.x + wf.w / 2, y = wf.y + wf.h / 2 })
	else
		-- Center the cursor on the screen
		local cscreen = hs.screen.mainScreen()
		local cres = cscreen:fullFrame()
		hs.mouse.setAbsolutePosition({ x = cres.x + cres.w / 2, y = cres.y + cres.h / 2 })
	end
end

return obj
