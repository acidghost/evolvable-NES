require 'torch'
require 'rnn'

utils = require './utils'
Inputs = require './inputs'
NeuralNetwork = require './network'

StateNumber = 1
State = savestate.create(StateNumber)
savestate.load(State)

Player = 1
MaxEnemies = 5
LeftMargin = 10
TopMargin = 40
LineHeight = 10
MaxDistance = 255

ButtonNames = {
	"A",
	--"B",
	--"Up",
	--"Down",
	"Left",
	"Right",
}

init_time = os.time()

Ninputs = 5
Noutputs = 3
net = NeuralNetwork(Ninputs, Noutputs)

while true do
	local mario = Inputs.getMario()
	local sprites = Inputs.getSprites()

	if os.time() - init_time > .05 then
		init_time = os.time()
	end

	-- local inputs = Inputs.getInputs()
	-- emu.message(string.format('%f %f %f', inputs[1], inputs[2], inputs[3]))
	-- emu.message(#inputs)

	local distances = Inputs.getDistances(mario, sprites)
	local tDistances = torch.Tensor(1, 5):fill(MaxDistance)
	for i = 1, #distances do
		tDistances[1][i] = distances[i]
	end

	local output = net:feed(tDistances)
	local padInput = joypad.get(Player)
	print(padInput)
	joypad.set(Player, { right = (output[1][1] > 0), left = (output[1][2] > 0), A = (output[1][3] > 0) })

	gui.text(LeftMargin, TopMargin, 'Mario ' .. (mario and string.format('%d, %d', mario.x, mario.y) or 'NaN'))
	for i = 1, MaxEnemies do
		local text = sprites[i] and string.format('%d, %d, %d', sprites[i].x, sprites[i].y, tDistances[1][i]) or 'NaN'
		gui.text(LeftMargin, TopMargin + (i*LineHeight), 'Sprite' .. i .. ' ' .. text)
	end



	emu.frameadvance()
end
