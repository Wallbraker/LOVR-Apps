-- Copyright 2021-2023, Collabora, Ltd.
-- SPDX-License-Identifier: BSL-1.0 or MIT-1.0


function lovr.conf(t)
	t.headset.drivers = {'openxr'}
	t.headset.overlay = true -- Controls if this is an overlay application
	t.window = nil -- No mirror window
end
