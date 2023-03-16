-- Copyright 2021-2023, Collabora, Ltd.
-- SPDX-License-Identifier: BSL-1.0 or MIT-1.0


local math = require 'math'

local model_left = nil
local model_right = nil
local model_box = nil
local tone = nil
local view = nil
local camera = nil

local quarterPI = (math.pi / 4) - 0.0001
local halfPI = (math.pi / 2) - 0.0001
local stateDragging = false
local stateCameHeading = -quarterPI
local stateCamPitch = -quarterPI
local stateDistance = 4

----
-- Setup mouse if we have a window.
local use_mouse = g_window_created
if use_mouse then
	lovr.mouse = require 'mouse'
end


--
--
-- Helper functions.
--
--

----
-- Create a tone, starts with full amplitude then quitens down.
function createTone()
	local length = 1
	local rate = 48000
	local frames = length * rate
	local frequency = 440
	local volume = 0.5

	local sound = lovr.data.newSound(frames, 'f32', 'stereo', rate)

	local data = {}
	for i = 1, frames do
		-- Start high but then quiet down.
		local v = volume * ((frames - i) / frames)

		local amplitude = math.sin((i - 1) * frequency / rate * (2 * math.pi)) * v
		data[2 * i - 1] = amplitude
		data[2 * i - 0] = amplitude
	end

	sound:setFrames(data)

	source = lovr.audio.newSource(sound)

	if false then
		source:setLooping(true)
	end

	return source
end

----
-- Sets the third-party view, the camera matrix is scaled for drawing.
function setThirdPartyView()
	local x = lovr.math.newQuat(stateCamPitch, 1, 0, 0)
	local y = lovr.math.newQuat(stateCameHeading, 0, 1, 0)
	local rot = y:mul(x)

	local x, y, z = rot:direction():mul(-stateDistance):unpack()
	view = lovr.math.newMat4():lookAt(vec3(x, y, z), vec3(0, 0, 0), vec3(0, 1, 0))
	camera = lovr.math.newMat4(view):invert():scale(0.2)
end

----
-- Helper function to draw a model at a device location.
function drawModelAtDevice(pass, model, device)
	if not lovr.headset.isTracked(device) then return end
	local x, y, z = lovr.headset.getPosition(device)
	local a, ax, ay, az = lovr.headset.getOrientation(device)

	pass:draw(model, x, y, z, 1, a, ax, ay, az)
end

----
-- Helper to draw a line along Z-axis of a device pose.
function drawLineZ(pass, device, length)
	if not lovr.headset.isTracked(device) then return end
	local x, y, z = lovr.headset.getPosition(device)
	local a, ax, ay, az = lovr.headset.getOrientation(device)
	local rot = lovr.math.newQuat(a, ax, ay, az)
	local rx, ry, rz = rot:direction():mul(length):unpack()

	pass:line(x, y, z, rx + x, ry + y, rz + z)
end

----
-- Helper clear the screen.
function clear(pass, r, g, b, a)
	pass:setColor(r, g, b, a)
	pass:setDepthWrite(false)
	pass:fill()
	pass:setDepthWrite(true)
end

----
-- Renders the scene, can handle differences between view and mirror.
function renderScene(pass, isMirror)
	local t = lovr.timer.getTime()

	pass:setColor(.15, .15, .15)
	pass:plane(0, 0, 0, 4, 4, math.pi / 2, 1, 0, 0)

	-- If it's the mirror view, draw the head
	if isMirror then
		pass:setColor(1, 1, 1)
		local x, y, z, angle, ax, ay, az = lovr.headset.getPose()
		pass:cube(x, y, z, .2, angle, ax, ay, az)
	else
		pass:setColor(1, 1, 1)
		local x, y, z, angle, ax, ay, az = lovr.headset.getPose()
		pass:cube(camera)
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

	local always_draw_controllers = true

	if not has_hands[1] or always_draw_controllers then
		drawModelAtDevice(pass, model_left, 'hand/left')
		drawLineZ(pass, 'hand/left/point', 1.0)
	end
	if not has_hands[2] or always_draw_controllers then
		drawModelAtDevice(pass, model_right, 'hand/right')
		drawLineZ(pass, 'hand/right/point', 1.0)
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
	if not stateDragging then return end

	stateCameHeading = stateCameHeading + rel_x * -0.003
	stateCamPitch = stateCamPitch + rel_y * -0.003

	if stateCamPitch < -halfPI then stateCamPitch = -halfPI end
	if stateCamPitch >  halfPI then stateCamPitch =  halfPI end

	setThirdPartyView()
end

----
-- Mouse scroll event callback.
function mouseScroll(rel_x, rel_y)
	stateDistance = stateDistance - rel_y * 0.1

	if stateDistance < 1.0 then stateDistance = 1.0 end

	setThirdPartyView()
end

----
-- Called on loading.
function lovr.load()
	-- For headset views
	lovr.graphics.setBackgroundColor(0.0, 0.0, 0.0, 0.0)

	-- Tone
	tone = createTone()

	-- Models
	model_left = lovr.graphics.newModel('valve-index_left.glb')
	model_right = lovr.graphics.newModel('valve-index_right.glb')
	model_box = lovr.graphics.newModel('box-textured.glb')

	-- Init camera & view matrix, for third party camera.
	setThirdPartyView()

	if use_mouse then
		-- Set mouse event callbacks.
		lovr.handlers['mousemoved'] = mouseMove
		lovr.handlers['wheelmoved'] = mouseScroll
	end
end

----
-- Called every frame to advance the state.
function lovr.update()
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
		stateDragging = true
		lovr.mouse.setRelativeMode(true)
	else
		stateDragging = false
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
	clear(pass, 0.5, 0.5, 0.9, 1.0)
	pass:origin()
	pass:transform(view)
	renderScene(pass, true)
end
