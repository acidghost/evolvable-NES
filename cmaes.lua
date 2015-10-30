do
	
	local CMAES = torch.class('CMAES')

	function CMAES:__init( genomeSize, maxGenerations, initialSigma )
		self.genomeSize = genomeSize
		self.maxGenerations = maxGenerations
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
		self.C = self.B * self.B * self.B:transpose(2, 1)
		self.invsqrtC = self.B * self.B * self.B:transpose(2, 1)
		self.eigeneval = 0
		self.chiN = genomeSize ^ .5 * (1 - 1/(4 * genomeSize) + 1/(21 * genomeSize^2))
	end

	function CMAES:generateOffspring()
		local offspring = {}
		for k = 1, self.lambda do
			local newOffspring = {}
			newOffspring.genome = self.xmean + self.B:mul(self.sigma) * (self.D:cmul(torch.randn(self.genomeSize, 1)))
			newOffspring.fitness = false
			table.insert(offspring, newOffspring)
		end

		self.offspring = offspring

		return offspring
	end

	function CMAES:setFitness( offspringID, fitness )
		self.offspring[offspringID].fitness = fitness
	end

end

return CMAES
