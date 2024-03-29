-- Copyright 2021-2023, Collabora, Ltd.
-- SPDX-License-Identifier: BSL-1.0 or MIT-1.0


local math = require 'math'
local third = require 'thirdMouse'

require 'helpers'

local model_left = nil
local model_right = nil
local model_box = nil
local tone = nil


----
-- Setup mouse if we have a window.
local use_mouse = g_window_created
if use_mouse then
	lovr.mouse = require 'mouse'
end


--
--
-- Settings
--
--

local lDrawAxis = true -- Should we draw axis crosses at controller poses?
local lDrawControllers = false -- Should controllers be drawn at all?
local lDrawControllersAlways = false -- Should controllers always be drawn?
local lDrawMirrorHeadCube = true -- Should we draw a head cube in mirror view?
local lDrawCameraCube = true -- Should we draw where the mirror camera is?
local lDrawPlane = false -- Should we draw the ground plane?
local lMirrorLookAtRightGrip = false -- Should mirror view always look at the right grip?


--
--
-- Helper functions.
--
--

----
-- Renders the scene, can handle differences between view and mirror.
function renderScene(pass, isMirror)
	local t = lovr.timer.getTime()

	-- Draw the plane.
	if lDrawPlane then
		pass:setColor(.15, .15, .15)
		pass:plane(0, 0, 0, 4, 4, math.pi / 2, 1, 0, 0)
	end

	-- If it's the mirror view, draw the head
	if lDrawMirrorHeadCube and isMirror then
		pass:setColor(1, 1, 1)
		local x, y, z, angle, ax, ay, az = lovr.headset.getPose()
		pass:cube(x, y, z, .2, angle, ax, ay, az)
	end

	if lDrawCameraCube and not isMirror then
		pass:setColor(1, 1, 1)
		pass:cube(third.getCameraObjectMat():scale(0.2))
	end

	-- White hand cubes
	pass:setColor(1, 1, 1)
	local has_hands = {false, false}
	for i, hand in ipairs({ 'left', 'right' }) do
		for _, joint in ipairs(lovr.headset.getSkeleton(hand) or {}) do
			has_hands[i] = true
			local x, y, z, radius, a, ax, ay, az = unpack(joint, 1, 8)
			pass:draw(model_box, x, y, z, radius, a, ax, ay, az)
		end
	end

	if lDrawAxis then
		drawAxisAtDevice(pass, 'hand/left', 0.1, 0.01)
		drawAxisAtDevice(pass, 'hand/left/point', 0.1, 0.01)
		drawAxisAtDevice(pass, 'hand/right', 0.1, 0.01)
		drawAxisAtDevice(pass, 'hand/right/point', 0.1, 0.01)

		pass:setDepthTest('none')
		drawTextAtDeviceLookingAtUser(pass, 'hand/left', 'grip', 0.01)
		drawTextAtDeviceLookingAtUser(pass, 'hand/left/point', 'aim', 0.01)
		drawTextAtDeviceLookingAtUser(pass, 'hand/right', 'grip', 0.01)
		drawTextAtDeviceLookingAtUser(pass, 'hand/right/point', 'aim', 0.01)
		pass:setDepthTest('gequal')
	else
		pass:setColor(1, 1, 1)
		drawLineForwardAtDevice(pass, 'hand/left/point', 1.0)
		drawLineForwardAtDevice(pass, 'hand/right/point', 1.0)
	end

	if lDrawControllers and lDrawControllersAlways then
		pass:setColor(1, 1, 1)
		drawModelAtDevice(pass, model_left, 'hand/left')
		drawModelAtDevice(pass, model_right, 'hand/right')
	end

	if not has_hands[1] and not lDrawControllersAlways and lDrawControllers then
		pass:setColor(1, 1, 1)
		drawModelAtDevice(pass, model_left, 'hand/left')
	end
	if not has_hands[2] and not lDrawControllersAlways and lDrawControllers then
		pass:setColor(1, 1, 1)
		drawModelAtDevice(pass, model_right, 'hand/right')
	end
end


--
--
-- Callbacks.
--
--

----
-- Mouse move event callback.
function mouseMove(x, y, rel_x, rel_y)
	third.mouseMove(x, y, rel_x, rel_y)
end

----
-- Mouse scroll event callback.
function mouseScroll(rel_x, rel_y)
	third.mouseScroll(rel_x, rel_y)
end

----
-- Called on loading.
function lovr.load()
	-- For headset views
	lovr.graphics.setBackgroundColor(0.0, 0.0, 0.0, 0.0)

	-- Tone
	tone = createTone()

	-- Models
	model_left = lovr.graphics.newModel('models/valve-index_left.glb')
	model_right = lovr.graphics.newModel('models/valve-index_right.glb')
	model_box = lovr.graphics.newModel('models/box-textured.glb')

	if use_mouse then
		-- Set mouse event callbacks.
		lovr.handlers['mousemoved'] = mouseMove
		lovr.handlers['wheelmoved'] = mouseScroll
	end
end

----
-- Called every frame to advance the state.
function lovr.update(dt)

	third.update(dt)

	local down = false
	for i, hand in ipairs(lovr.headset.getHands()) do
		if lovr.headset.isDown(hand, 'trigger') then
			down = true
		end
	end

	if down then
		tone:play()
	end

	if not use_mouse then
		return
	end

	if (lovr.mouse.isDown(1)) then
		third.setDragging(true)
		lovr.mouse.setRelativeMode(true)
	else
		third.setDragging(false)
		lovr.mouse.setRelativeMode(false)
	end
end

----
-- Callback to draw the main scene, called once for each view.
function lovr.draw(pass)
	renderScene(pass, false)
end

----
-- Callback to draw the mirror window.
function lovr.mirror(pass)
	drawClear(pass, 0.5, 0.5, 0.9, 1.0)
	pass:origin()

	if lMirrorLookAtRightGrip then
		local at = vec3(lovr.headset.getPosition('hand/right'))
		local from = vec3(lovr.headset.getPosition())
		local up = vec3(0, 1, 0)

		local view = lovr.math.newMat4():lookAt(from, at, up)
		pass:transform(view)
	else
		pass:transform(third.getCameraViewMat())
	end

	renderScene(pass, true)
end
