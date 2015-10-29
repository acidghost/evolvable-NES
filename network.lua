do

	local NeuralNetwork = torch.class('NeuralNetwork')

	function NeuralNetwork:__init(nin, nout)
		self.nin = nin
		self.nout = nout

		net = nn.Sequential()
		net:add(nn.Linear(nin, nout))
		net:add(nn.Tanh())

		self.net = net
	end

	function NeuralNetwork:feed(input)
		return self.net:forward(input)
	end

	function NeuralNetwork:setWeights(weights)
		self.net.modules[1].weights = weights
	end

end

return NeuralNetwork
