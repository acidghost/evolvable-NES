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
MaxEvaluations = 400

ButtonNames = {
	"A",
	--"B",
	--"Up",
	--"Down",
	"Left",
	"Right",
}

Ninputs = 5
Nhidden = 2
Noutputs = 3
net = NeuralNetwork(Ninputs, Nhidden, Noutputs)

GenomeSize = Ninputs * Nhidden + Nhidden * Noutputs
-- cmaes = CMAES(GenomeSize, 100)
-- offspring = cmaes:generateOffspring()
-- currentOff = 1

framecounter = 0

while true do
	if framecounter > MaxEvaluations then
		savestate.load(State)
		framecounter = 0
		net:reset()
	else
		local mario = Inputs.getMario()
		local sprites = Inputs.getSprites()

		-- local inputs = Inputs.getInputs()
		-- emu.message(string.format('%f %f %f', inputs[1], inputs[2], inputs[3]))
		-- emu.message(#inputs)

		local distances = Inputs.getDistances(mario, sprites)
		local tDistances = torch.Tensor(1, 5):fill(MaxDistance)
		for i = 1, #distances do
			tDistances[1][i] = distances[i]
		end
		tDistances = tDistances:div(MaxDistance)

		local output = net:feed(tDistances)
		local padInput = joypad.get(Player)
		joypad.set(Player, { right = (output[1][1] > 0), left = (output[1][2] > 0), A = (output[1][3] > 0) })

		gui.text(LeftMargin, TopMargin, 'Mario ' .. (mario and string.format('%d, %d', mario.x, mario.y) or 'NaN'))
		for i = 1, MaxEnemies do
			local text = sprites[i] and string.format('%d, %d, %d', sprites[i].x, sprites[i].y, tDistances[1][i]) or 'NaN'
			gui.text(LeftMargin, TopMargin + (i*LineHeight), 'Sprite' .. i .. ' ' .. text)
		end

		framecounter = framecounter + 1
	end

	emu.frameadvance()
end
