do
	
	local CMAES = torch.class('CMAES')

	function CMAES:__init( genomeSize, initialSigma )
		self.genomeSize = genomeSize
		self.sigma = initialSigma or 0.5
		self.xmean = torch.rand(genomeSize, 1)

		-- Strategy parameter setting: Selection
		self.lambda = 4 + torch.floor(3 * torch.log(genomeSize))
		self.mu = self.lambda / 2
		self.weights = torch.range(1, self.mu):log():mul(-1):add(torch.log(self.mu + 1/2))
		self.mu = torch.floor(self.mu)
		self.weights = self.weights:div(self.weights:sum())
		self.mueff = self.weights:sum()^2 / self.weights:pow(2):sum()

		-- Strategy parameter setting: Adaptation
		self.cc = (4 + self.mueff / genomeSize) / (genomeSize + 4 + 2 * self.mueff / genomeSize)
		self.cs = (self.mueff + 2) / (genomeSize + self.mueff + 5)
		self.c1 = 2 / ((genomeSize + 1.3)^2 + self.mueff)
		self.cmu = math.min(1 - self.c1, 2 * (self.mueff - 2 + 1 / self.mueff) / ((genomeSize + 2)^2 + self.mueff))
		self.damps = 1 + 2 * math.max(0, torch.sqrt((self.mueff-1) / (genomeSize + 1))-1) + self.cs

		-- Initialize dynamic (internal) strategy parameters and constants
		self.pc = torch.zeros(genomeSize, 1)
		self.ps = torch.zeros(genomeSize, 1)
		self.B = torch.eye(genomeSize, genomeSize)
		self.D = torch.ones(genomeSize, 1)
		self.C = self.B * self.B * self.B:t()
		self.invsqrtC = self.B * self.B * self.B:t()
		self.eigeneval = 0
		self.chiN = genomeSize ^ .5 * (1 - 1/(4 * genomeSize) + 1/(21 * genomeSize^2))

		self.generation = 0
		self.counteval = 0
	end

	function CMAES:generateOffspring()
		local offspring = {}
		for k = 1, self.lambda do
			local newOffspring = {}
			newOffspring.genome = self.xmean + self.B * self.sigma * (self.D:cmul(torch.randn(self.genomeSize, 1)))
			newOffspring.fitness = false
			table.insert(offspring, newOffspring)
		end

		self.offspring = offspring
		self.generation = self.generation + 1

		return offspring
	end

	function CMAES:setFitness( offspringID, fitness )
		self.offspring[offspringID].fitness = fitness
		self.counteval = self.counteval + 1
	end

	function CMAES:endGeneration()
		-- Sort by fitness and compute weighted mean into xmean
		local fitnesses = _.map(self.offspring, function(k, v) return v.fitness or 0 end)
		local fitnessTensor = torch.Tensor(fitnesses)
		local sorted, sortedIndexes = fitnessTensor:sort(1, true)
		sortedIndexes = sortedIndexes:reshape(self.lambda, 1)
		local xold = self.xmean
		local genomes = _.map(self.offspring, function(k, v) return v.genome:totable() end)
		local genomesTensor = torch.Tensor(genomes)
		local selected = genomesTensor:index(1, sortedIndexes[{ {1, self.mu}, 1 }]):reshape(self.genomeSize, self.mu)
		self.xmean = selected * self.weights

		-- Cumulation: Update evolution paths
		self.ps = (self.ps * (1 - self.cs) + (self.invsqrtC * (self.xmean - xold) * torch.sqrt(self.cs * (1-self.cs) * self.mueff))) / self.sigma
		local hsig = self.ps:pow(2):sum() / (1 - math.pow(1 - self.cs, 2*self.counteval/self.lambda)) / self.genomeSize < 2 + 4/(self.genomeSize+1) and 1 or 0
		self.pc = self.pc * (1-self.cc) + (self.xmean - xold) * (hsig * torch.sqrt(self.cc*(2-self.cc)*self.mueff)) / self.sigma

		-- Adapt covariance matrix C
		local mudiff = selected * (1/self.sigma) - torch.repeatTensor(xold, 1, self.mu)
		self.C = self.C * (1-self.c1-self.cmu) + (self.pc * self.pc:t() + self.C * ((1-hsig) * self.cc * (2-self.cc))) * self.c1 + (mudiff * self.cmu) * self.weights:diag() * mudiff:t()

		-- Adapt step size sigma
		self.sigma = self.sigma * torch.exp((self.cs/self.damps) * (self.ps:norm()/self.chiN - 1))

		-- Update B and D from C
		if self.counteval - self.eigeneval > self.lambda/(self.c1+self.cmu)/self.genomeSize/10 then
			self.eigeneval = self.counteval
			self.C = torch.triu(self.C) + torch.triu(self.C, 1):t()
			self.D, self.B = torch.eig(self.C, 'V')
			self.D = self.D[{{}, 1}]
			self.D = torch.sqrt(self.D)
			self.invsqrtC = self.B * self.D:pow(-1):diag() * self.B:t()
		end

		return { best = self.offspring[sortedIndexes[{1,1}]] }
	end

end

return CMAES
