-- Copyright 2021-2023, Collabora, Ltd.
-- SPDX-License-Identifier: BSL-1.0 or MIT-1.0


local math = require 'math'

require 'helpers'

--
--
-- Settings
--
--

local lAxisStart = 0.005 -- Axis start 0.5cm
local lAxisStop = 0.015 -- Axis size 1.5cm


--
--
-- Helper functions.
--
--

----
-- Renders the scene, can handle differences between view and mirror.
function renderScene(pass, isMirror)
	local t = lovr.timer.getTime()

	pass:setColor(.15, .15, .15)
	pass:plane(0, 0, 0, 4, 4, math.pi / 2, 1, 0, 0)

	-- Axis at each joint
	pass:setColor(1, 1, 1)
	local has_hands = {false, false}
	for i, hand in ipairs({ 'left', 'right' }) do
		for _, joint in ipairs(lovr.headset.getSkeleton(hand) or {}) do
			has_hands[i] = true
			local x, y, z, radius, a, ax, ay, az = unpack(joint, 1, 8)
			local center = vec3(x, y, z)
			local rot = quat(a, ax, ay, az)

			drawAxis(pass, center, rot, lAxisStop, lAxisStart)
			pass:setColor(1, 1, 1)
			pass:cube(center, lAxisStart, rot)
		end
	end
end


--
--
-- Callbacks.
--
--

----
-- Called on loading.
function lovr.load()
	-- For headset views
	lovr.graphics.setBackgroundColor(0.0, 0.0, 0.0, 0.0)
end

----
-- Called every frame to advance the state.
function lovr.update(dt)

end

----
-- Callback to draw the main scene, called once for each view.
function lovr.draw(pass)
	renderScene(pass, false)
end
