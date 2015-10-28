State = savestate.create(1)
savestate.load(State)

while true do
	gui.text(50, 50, 'Hello, world!')
	emu.frameadvance()
end
