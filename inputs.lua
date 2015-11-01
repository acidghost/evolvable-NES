do
	
	local Inputs = torch.class('Inputs')

	local BoxRadius = 6
	local InputSize = (BoxRadius*2+1)*(BoxRadius*2+1)

	function Inputs.getMario()
		local marioX = memory.readbyte(0x6D) * 0x100 + memory.readbyte(0x86)
		local marioY = memory.readbyte(0x03B8)+16
	
		local screenX = memory.readbyte(0x03AD)
		local screenY = memory.readbyte(0x03B8)

		return { x= marioX, y= marioY }
	end

	function Inputs.getTile(dx, dy, mario)
		local x = mario.x + dx + 8
		local y = mario.y + dy - 16
		local page = math.floor(x/256)%2

		local subx = math.floor((x%256)/16)
		local suby = math.floor((y - 32)/16)
		-- 0x0500-0x069F	Current tile
		local addr = 0x500 + page*13*16+suby*16+subx
			
		if suby >= 13 or suby < 0 then
			return 0
		end
			
		if memory.readbyte(addr) ~= 0 then
			return 1
		else
			return 0
		end
	end

	function Inputs.getSprites()
		local sprites = {}
		for slot=0,4 do
			-- 0x000F-0x0013 Enemy active?
			local enemy = memory.readbyte(0xF+slot)
			if enemy ~= 0 then
				-- 0x006E-0x0072 Enemy horizontal position in level
				-- 0x0087/B	Enemy x position on screen
				local inLevel = memory.readbyte(0x6E + slot)
				local onScreen = memory.readbyte(0x87 + slot)
				local ex = inLevel * 0x100 + onScreen
				-- 0x00CF-0x00D3	Enemy y pos on screen (multiply with value at 0x00B6/A to get level y pos)
				local ey = memory.readbyte(0xCF + slot) + 24
				
				--emu.print(ex .. ' ' .. ey .. ' ' .. inLevel .. ' ' .. onScreen)
				sprites[#sprites+1] = { x = ex, y = ey }
			end
		end

		-- emu.print('Found ' .. #sprites .. ' sprites')
			
		return sprites
	end

	function Inputs.getMarioScore()
		-- 0x07DD-0x07E2	Mario score (1000000 100000 10000 1000 100 10)
		local addresses = torch.range(0x7DD, 0x7E2)
		local scores = { 1000000, 100000, 10000, 1000, 100, 10 }
		local score = 0
		-- FIXME!
		for i = 1, addresses:size()[1] do
			score = score + (scores[i] * memory.readbyte(addresses[i]))
		end

		return score
	end

	function Inputs.getMarioState()
		-- 0x000E	Player's state
		local states = { 
			'Leftmost of screen',
			'Climbing vine',
			'Entering reversed-L pipe',
			'Going down a pipe',
			'Autowalk',
			'Autowalk',
			'Player dies',
			'Entering area',
			'Normal',
			'Cannot move',
			--' ',
			'Dying',
			'Palette cycling, can\'t move'
		}
		local stateCode = memory.readbyte(0xE)

		return states[stateCode]
	end

	function Inputs.getTime()
		-- 0x07F8/A	Digits of time (100 10 1)
		local addresses = torch.range(0x7F8, 0x7FA)
		local digits = { 100, 10, 1 }
		local time = 0
		for i = 1, addresses:size(1) do
			time = time + (digits[i] * memory.readbyte(addresses[i]))
		end

		return time
	end

	function Inputs.getInputs()
		local mario = Inputs.getMario()
		
		sprites = Inputs.getSprites()
		
		local inputs = {}
		
		for dy=-BoxRadius*16,BoxRadius*16,16 do
			for dx=-BoxRadius*16,BoxRadius*16,16 do
				inputs[#inputs+1] = 0
				
				local tile = Inputs.getTile(dx, dy, mario)
				if tile == 1 and mario.y + dy < 0x1B0 then
					inputs[#inputs] = 1
				end
				
				for i = 1,#sprites do
					local distx = math.abs(sprites[i].x - (mario.x + dx))
					local disty = math.abs(sprites[i].y - (mario.y + dy))
					if distx <= 8 and disty <= 8 then
						inputs[#inputs] = -1
					end
				end
			end
		end
		
		--mariovx = memory.read_s8(0x7B)
		--mariovy = memory.read_s8(0x7D)
		
		return inputs
	end

	function Inputs.getDistances(mario, sprites)
		local distances = {}
		for i = 1, #sprites do
			table.insert(distances, utils.distance(mario, sprites[i]))
		end

		return distances
	end

end

return Inputs
