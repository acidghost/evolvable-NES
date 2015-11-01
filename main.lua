require 'torch'
require 'rnn'

utils = require './utils'
Inputs = require './inputs'
NeuralNetwork = require './network'
CMAES = require './cmaes'

StateNumber = 1
State = savestate.create(StateNumber)
savestate.load(State)

Player = 1
MaxEnemies = 5
LeftMargin = 10
TopMargin = 40
BottomMargin = 230
LineHeight = 10
MaxDistance = 255
MaxTime = 400
MaxEvaluations = 1000
EndLevel = 3000
EndLevelBonus = 1000

ButtonNames = {
	"A",
	--"B",
	--"Up",
	--"Down",
	"Left",
	"Right",
}

Ninputs = 5
Nhidden = 4
Noutputs = 3
net = NeuralNetwork(Ninputs, Nhidden, Noutputs)

--			|hidden weights| + |hidden bias| + |out weights| + |out bias|
GenomeSize = Nhidden * Ninputs + Nhidden + Noutputs * Nhidden + Noutputs
MaxGenerations = 100
cmaes = CMAES(GenomeSize)
Lambda = cmaes.lambda
offspring = cmaes:generateOffspring()
currentOffspring = 1
generationCount = 1

net:setWeights(offspring[currentOffspring].genome)

GenerationStats = {}

framecounter = 0

while true do
	emu.speedmode('turbo')
	local mario = Inputs.getMario()

	local marioState = Inputs.getMarioState()
	local marioDead = marioState == 'Dying' or marioState == 'Player dies'

	gui.text(LeftMargin, BottomMargin - 3*LineHeight, 'Generation: ' .. generationCount)
	gui.text(LeftMargin, BottomMargin - 2*LineHeight, 'Individual: ' .. currentOffspring)

	if framecounter > MaxEvaluations or marioDead then
		local marioScore = Inputs.getMarioScore() + mario.x + (mario.x > EndLevel and EndLevelBonus or 0)
		local gameTime = Inputs.getTime()

		local fitness = marioScore + (MaxTime - gameTime)

		-- if marioDead then print('Mario\'s dead... :(') end

		cmaes:setFitness(currentOffspring, fitness)

		-- print('Evaluated offspring ' .. currentOffspring .. ' with fitness of ' .. fitness .. ' ended in ' .. mario.x)

		framecounter = 0
		currentOffspring = currentOffspring + 1

		if currentOffspring > Lambda then
			local stats = cmaes:endGeneration()
			print('Best fit (' .. generationCount .. '): ' .. stats.best.fitness)

			table.insert(GenerationStats, stats)

			if generationCount == MaxGenerations then
				_.each(GenerationStats, function(k, v)
					print(string.format('%.4f', v.best.fitness))
					print(v.best.genome)
				end)
				os.exit()
			end

			offspring = cmaes:generateOffspring()
			currentOffspring = 1
			generationCount = generationCount + 1
		end

		net:setWeights(offspring[currentOffspring].genome)
		savestate.load(State)
	else
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
		joypad.set(Player, { right = (output[1][1] > 0), left = (output[1][2] > 0), A = (output[1][3] > 0) })

		gui.text(LeftMargin, TopMargin, 'Mario ' .. (mario and string.format('%d, %d', mario.x, mario.y) or 'NaN'))
		for i = 1, MaxEnemies do
			local text = sprites[i] and string.format('%d, %d, %.3f', sprites[i].x, sprites[i].y, tDistances[1][i]) or 'NaN'
			gui.text(LeftMargin, TopMargin + (i*LineHeight), 'Sprite' .. i .. ' ' .. text)
		end

		framecounter = framecounter + 1
	end

	emu.frameadvance()
end
