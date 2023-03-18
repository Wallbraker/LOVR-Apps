-- Copyright 2021-2023, Collabora, Ltd.
-- SPDX-License-Identifier: BSL-1.0 or MIT-1.0

--
--
-- File for mouse based third person view controller.
--
--

local math = require 'math'

local quarterPI = (math.pi / 4) - 0.0001
local halfPI = (math.pi / 2) - 0.0001
local stateDragging = false
local stateCameHeading = -quarterPI
local stateCamPitch = -quarterPI
local stateDistance = 4

local view = nil
local camera = nil

----
-- Sets the third-party view, the camera matrix is scaled for drawing.
local setThirdPartyView = function()
	local x = lovr.math.newQuat(stateCamPitch, 1, 0, 0)
	local y = lovr.math.newQuat(stateCameHeading, 0, 1, 0)
	local rot = y:mul(x)

	local x, y, z = rot:direction():mul(-stateDistance):unpack()
	view = lovr.math.newMat4():lookAt(vec3(x, y, z), vec3(0, 0, 0), vec3(0, 1, 0))
	camera = lovr.math.newMat4(view):invert()
end

-- Make sure to setup the initial state properly
setThirdPartyView()


----
-- Exported interface, return only a table with functions.
local third = {}

----
-- Called every frame with delta time in seconds.
function third.update(dt)
	-- No-op
end

----
-- Mouse movement.
function third.mouseMove(x, y, rel_x, rel_y)

	if not stateDragging then return end

	stateCameHeading = stateCameHeading + rel_x * -0.003
	stateCamPitch = stateCamPitch + rel_y * -0.003

	if stateCamPitch < -halfPI then stateCamPitch = -halfPI end
	if stateCamPitch >  halfPI then stateCamPitch =  halfPI end

	setThirdPartyView()
end

----
-- Mouse scroll wheel.
function third.mouseScroll(rel_x, rel_y)
	stateDistance = stateDistance - rel_y * 0.1

	if stateDistance < 1.0 then stateDistance = 1.0 end

	setThirdPartyView()
end

----
-- Is the mouse doing a clicked dragging.
function third.setDragging(dragging)
	stateDragging = dragging
end

----
-- Return the view matrix for the camera.
function third.getCameraViewMat()
	return lovr.math.newMat4(view)
end

----
-- Return the object matrix for the camera (where it is position in space).
function third.getCameraObjectMat()
	return lovr.math.newMat4(camera)
end

return third
