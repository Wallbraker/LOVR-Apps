-- Copyright 2021-2023, Collabora, Ltd.
-- SPDX-License-Identifier: BSL-1.0 or MIT-1.0


----
-- Local options
local lTryToUseWindow = true
local lOverlay = true


----
-- Global values carried forward to main.lua
g_window_created = false


----
-- Parse a single argument, returns false when it's unknown.
local parseArg = function(arg)

	if arg == '--no-window' then
		lTryToUseWindow = false
	elseif arg == '--no-overlay' then
		lOverlay = false
	else
		print("Unknown argument '" .. arg .. "'")
		return false
	end

	return true
end


----
-- Parse arguments
local parseArgs = function(args)
	local has_unknown
	for k, v in pairs(arg) do
		local ik = tonumber(k)
		if ik and ik > 0 then
			if not parseArg(v) then has_unknown = true end
		end
	end

	if has_unknown then
		print("Accpeted argumetns:")
		print("\t--no-window    No mirror window")
		print("\t--no-overlay   Don't enter overlay mode")
	end
end

----
-- Callback on start.
function lovr.conf(t)
	parseArgs(arg)

	t.headset.drivers = {'openxr'}
	t.headset.overlay = lOverlay -- Controls if this is an overlay application


	if not lTryToUseWindow or t.window == nil then
		t.window = nil
		g_window_created = false
	else
		g_window_created = true
		t.window.width = 800
		t.window.height = 600
		t.window.resizable = true
		t.window.title = "Overlay Test"
	end
end
