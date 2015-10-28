torch = require 'torch'

State = savestate.create(1)
savestate.load(State)

init_time = os.time()

while true do
	--emu.print('Hello, frame!')

	if os.time() - init_time > 5 then
		emu.softreset()
		init_time = os.time()
		savestate.load(State)
	end

	emu.frameadvance()
end
