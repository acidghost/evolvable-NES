do

	local NeuralNetwork = torch.class('NeuralNetwork')

	function NeuralNetwork:__init(nin, nhidden, nout)
		self.nin = nin
		self.nhidden = nhidden
		self.nout = nout

		net = nn.Sequential()
		-- hidden layer
		net:add(nn.Linear(nin, nhidden))
		net:add(nn.Tanh())

		-- output layer
		net:add(nn.Linear(nhidden, nout))
		net:add(nn.Tanh())

		self.net = net
	end

	function NeuralNetwork:feed(input)
		return self.net:forward(input)
	end

	function NeuralNetwork:setWeights(weightsHid, biasHid, weightsOut, biasOut)
		self.net.modules[1].weights = weightsHid
		self.net.modules[1].bias = biasHid
		self.net.modules[3].weights = weightsOut
		self.net.modules[3].bias = biasOut
	end

	function NeuralNetwork:getWeights()
		local weightsHid = self.net.modules[1].weights:reshape(1, self.nin * self.nhidden)
		local biasHid = self.net.modules[1].bias:reshape(1, self.nhidden)
		local weightsOut = self.net.modules[3].bias:reshape(1, self.nhidden * self.nout)
		local biasOut = self.net.modules[3].bias:reshape(1, self.nout)

		return weightsHid, biasHid, weightsOut, biasOut
	end

	function NeuralNetwork:reset()
		self.net:reset()
	end

end

return NeuralNetwork
