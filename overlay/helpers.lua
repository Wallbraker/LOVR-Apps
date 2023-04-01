-- Copyright 2021-2023, Collabora, Ltd.
-- SPDX-License-Identifier: BSL-1.0 or MIT-1.0

local math = require 'math'

local quat = lovr.math.quat
local vec3 = lovr.math.vec3
local mat4 = lovr.math.mat4

local isTracked = lovr.headset.isTracked
local getPosition = lovr.headset.getPosition
local getOrientation = lovr.headset.getOrientation
local getPositionVec3 = function(device) return vec3(getPosition(device)) end
local getOrientationQuat = function(device) return quat(getOrientation(device)) end


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
-- Helper function to draw a model at a device location.
function drawModelAtDevice(pass, model, device)
	if not isTracked(device) then return end

	local pos = getPositionVec3(device)
	local rot = getOrientationQuat(device)

	pass:draw(model, pos, 1, rot)
end

----
-- Draws a model with a offset, pos_offset is rotated with the device rotation.
function drawModelAtDeviceWithOffset(pass, model, device, pos_offset, rot_offset)
	if not isTracked(device) then return end

	local pos = getPositionVec3(device)
	local rot = getOrientationQuat(device)

	-- Get new orientation.
	pos = pos + rot * pos_offset
	rot = rot * rot_offset

	-- Do the drawing.
	pass:draw(model, pos, 1, rot)
end

----
-- Draws a model, that is rotated around y axis 180 dagrees.
function drawModelAtDeviceY180(pass, model, device)
	-- Needs to turn around the headset 180.
	local y180 = quat(0, 1, 0, 0, true)
	local ident = vec3(0, 0, 0)

	-- Pass on.
	drawModelAtDeviceWithOffset(pass, model, device, ident, y180)
end

----
-- Helper to draw a line at a device pose.
function drawLineAtDevice(pass, device, line)
	if not isTracked(device) then return end

	local rot = getOrientationQuat(device)
	local p1 = getPositionVec3(device)
	local p2 = rot * line + p1

	pass:line(p1, p2)
end

----
-- Helper to draw a line along the negative Z-axis of a device pose.
function drawLineForwardAtDevice(pass, device, length)
	drawLineAtDevice(pass, device, vec3(0, 0, -length))
end

----
-- Helper to draw a axis cross at a device pose.
function drawAxisAtDevice(pass, device, stop, start)
	if not isTracked(device) then return end

	local center = getPositionVec3(device)
	local rot = getOrientationQuat(device)

	start = start or 0.0

	local x = rot:mul(vec3(1, 0, 0))
	local x_start = x * start
	local x_stop = x * stop

	local y = rot:mul(vec3(0, 1, 0))
	local y_start = y * start
	local y_stop = y * stop

	local z = rot:mul(vec3(0, 0, 1))
	local z_start = z * start
	local z_stop = z * stop

	local n1 = 0.0 -- Negative non-current axis
	local n2 = 0.5 -- Negative current axis
	local p1 = 0.2 -- Positive non-current axis
	local p2 = 1.0 -- Positive current axis

	pass:setColor(p2, p1, p1)
	pass:line(center + x_start, center + x_stop)
	pass:setColor(n2, n1, n1)
	pass:line(center - x_start, center - x_stop)

	pass:setColor(p1, p2, p1)
	pass:line(center + y_start, center + y_stop)
	pass:setColor(n1, n2, n1)
	pass:line(center - y_start, center - y_stop)

	pass:setColor(p1, p1, p2)
	pass:line(center + z_start, center + z_stop)
	pass:setColor(n1, n1, n2)
	pass:line(center - z_start, center - z_stop)
end

----
-- Draws text at the location of the given device
-- but rotated so it is always facing the user.
function drawTextAtDeviceLookingAtUser(pass, device, text, scale)
	if not isTracked(device) then return end

	scale = scale or 0.1
	text = text or device

	local user = getPositionVec3()
	local pos = getPositionVec3(device)

	local view = mat4():target(pos, user, vec3(0, 1, 0))
	view = view:scale(vec3(-scale, scale, scale))

	pass:setColor(1, 1, 1)
	pass:text(text, view)
end

----
-- Helper clear the screen.
function drawClear(pass, r, g, b, a)
	pass:setColor(r, g, b, a)
	pass:setDepthWrite(false)
	pass:fill()
	pass:setDepthWrite(true)
end
