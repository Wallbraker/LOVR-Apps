local model_left = nil
local model_right = nil
local view = nil

function lovr.load()
	model_left = lovr.graphics.newModel('valve-index_left.glb')
	model_right = lovr.graphics.newModel('valve-index_right.glb')

	-- Camera view
	local x, y, z = -3, 3, 3
	camera = lovr.math.newMat4():lookAt(vec3(x, y, z), vec3(0, 0, 0), vec3(0, 1, 0))
	view = lovr.math.newMat4(camera)
end

function lovr.update()
	local down = false
	for i, hand in ipairs(lovr.headset.getHands()) do
		if lovr.headset.isDown(hand, 'trigger') then
			down = true
		end
	end
end

function draw_model_at_device(model, device)
	local x, y, z = lovr.headset.getPosition(device)
	local a, ax, ay, az = lovr.headset.getOrientation(device)

	model:draw(x, y, z, 1, a, ax, ay, az)
end

function renderScene(isMirror)
	local t = lovr.timer.getTime()

	lovr.graphics.setColor(.15, .15, .15)
	lovr.graphics.plane('fill', 0, 0, 0, 4, 4, math.pi / 2, 1, 0, 0)

	-- If it's the mirror view, draw the camera
	if isMirror then
		lovr.graphics.setColor(1, 1, 1)
		local x, y, z, angle, ax, ay, az = lovr.headset.getPose()
		lovr.graphics.cube('fill', x, y, z, .2, angle, ax, ay, az)
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
		draw_model_at_device(model_left, 'hand/left')
		draw_model_at_device(model_right, 'hand/right')
	end
end

function lovr.draw()
	lovr.graphics.setBackgroundColor(0.0, 0.0, 0.0, 0.0)
	renderScene(false)
end

function lovr.mirror()
	lovr.graphics.setBackgroundColor(0.5, 0.5, 0.9, 1.0)
	lovr.graphics.clear()
	lovr.graphics.origin()
	lovr.graphics.transform(view)
	renderScene(true)

	lovr.graphics.setBackgroundColor(0.0, 0.0, 0.0, 0.0)
end
