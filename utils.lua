local utils = {}

utils.distance = function(x, y)
	return torch.sqrt(torch.pow(x.x - y.x, 2) + torch.pow(x.y - y.y, 2))
end

return utils
