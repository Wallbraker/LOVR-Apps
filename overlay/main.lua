
lovr.mouse = require 'mouse'
local math = require 'math'

local model_left = nil
local model_right = nil
local view = nil
local camera = nill

local quarterPI = (math.pi / 4) - 0.0001
local halfPI = (math.pi / 2) - 0.0001
local stateDragging = false
local stateCameHeading = -quarterPI
local stateCamPitch = -quarterPI
local stateDistance = 4


--
--
-- Helper functions.
--
--

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
function drawModelAtDevice(model, device)
	if not lovr.headset.isTracked(device) then return end
	local x, y, z = lovr.headset.getPosition(device)
	local a, ax, ay, az = lovr.headset.getOrientation(device)

	model:draw(x, y, z, 1, a, ax, ay, az)
end

----
-- Renders the scene, can handle differences between view and mirror.
function renderScene(isMirror)
	local t = lovr.timer.getTime()

	lovr.graphics.setColor(.15, .15, .15)
	lovr.graphics.plane('fill', 0, 0, 0, 4, 4, math.pi / 2, 1, 0, 0)

	-- If it's the mirror view, draw the head
	if isMirror then
		lovr.graphics.setColor(1, 1, 1)
		local x, y, z, angle, ax, ay, az = lovr.headset.getPose()
		lovr.graphics.cube('fill', x, y, z, .2, angle, ax, ay, az)
	else
		lovr.graphics.setColor(1, 1, 1)
		local x, y, z, angle, ax, ay, az = lovr.headset.getPose()
		lovr.graphics.cube('fill', camera)
	end

	-- White hand cubes
	lovr.graphics.setColor(1, 1, 1)
	local has_hands = false
	for _, hand in ipairs({ 'left', 'right' }) do
		for _, joint in ipairs(lovr.headset.getSkeleton(hand) or {}) do
			has_hands = true
			local x, y, z, a, ax, ay, az = unpack(joint, 1, 7)
			lovr.graphics.cube('fill', x, y, z, 0.01, a, ax, ay, az)
		end
	end

	if true then
		drawModelAtDevice(model_left, 'hand/left')
		drawModelAtDevice(model_right, 'hand/right')
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
	model_left = lovr.graphics.newModel('valve-index_left.glb')
	model_right = lovr.graphics.newModel('valve-index_right.glb')

	-- Init camera & view matrix, for third party camera.
	setThirdPartyView()

	-- Set mouse event callbacks.
	lovr.handlers['mousemoved'] = mouse_move
	lovr.handlers['wheelmoved'] = wheel_move
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
function lovr.draw()
	lovr.graphics.setBackgroundColor(0.0, 0.0, 0.0, 0.0)
	renderScene(false)
end

----
-- Callback to draw the mirror window.
function lovr.mirror()
	lovr.graphics.setBackgroundColor(0.5, 0.5, 0.9, 1.0)
	lovr.graphics.clear()
	lovr.graphics.origin()
	lovr.graphics.transform(view)
	renderScene(true)

	lovr.graphics.setBackgroundColor(0.0, 0.0, 0.0, 0.0)
end
