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

	function Inputs.getExtendedSprites()
		return {}
	end


	function Inputs.getInputs()
		local mario = Inputs.getMario()
		
		sprites = Inputs.getSprites()
		extended = Inputs.getExtendedSprites()
		
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

				for i = 1,#extended do
					local distx = math.abs(extended[i].x - (mario.x + dx))
					local disty = math.abs(extended[i].y - (mario.y + dy))
					if distx < 8 and disty < 8 then
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
