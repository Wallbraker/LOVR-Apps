function lovr.conf(t)
	t.headset.drivers = {'openxr'}
	t.headset.overlay = true

	if false or t.window == nil then
		t.window = nil
	else
		t.window.width = 800
		t.window.height = 600
		t.window.resizable = true
		t.window.title = "Overlay Test"
	end
end
