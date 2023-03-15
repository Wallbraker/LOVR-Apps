-- Copyright 2021-2023, Collabora, Ltd.
-- SPDX-License-Identifier: BSL-1.0 or MIT-1.0


----
-- Local options
local try_to_use_window = true

----
-- Global values carried forward to main.lua
g_window_created = false

function lovr.conf(t)
	t.headset.drivers = {'openxr'}
	t.headset.overlay = true -- Controls if this is an overlay application


	if not try_to_use_window or t.window == nil then
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
