function label(text, x, y, size)
	-- Add text with a backgound box at a given location
	aspect = 0.65
	width = string.len(text)*size*aspect
	gui.drawBox(x, y, x+width,y+size,0x00000000,0x80FF0000)
	gui.drawText(x, y, text, 0xFF000000, size)
end

marioheight = 32
mariowidth = 16
mapscale = 0.8  -- Size of map relative to size of the screen

RAM = {
	marioX = 0xD1,
	marioY = 0xD3,
	layer1x = 0x1A,
	layer1y = 0x1C,
	screentiles = 0x1C800,
}

MAP = {
	x = 0,
	width = 270*mapscale,
	y = 0,
	height = 200*mapscale
}

function getPositions()
	-- Get the positions of the Mario Sprite
	marioX = memory.read_s16_le(RAM.marioX)
	marioY = memory.read_s16_le(RAM.marioY)
	label("M", marioX, 10, 10)
	local layer1x = memory.read_s16_le(RAM.layer1x);
	local layer1y = memory.read_s16_le(RAM.layer1y);
	
	screenX = marioX-layer1x
	screenY = marioY-layer1y
end

function getTile(dx, dy)
	-- Read the memory for a map location relative to Mario's current position.
	x = math.floor((marioX+dx+8)/16)
	y = math.floor((marioY+dy)/16)	
	return memory.readbyte(RAM.screentiles + math.floor(x/0x10)*0x1B0 + y*0x10 + x%0x10)	
end	

function getSprites()
	local sprites = {}
	for slot=0,11 do
		local status = memory.readbyte(0x14C8+slot)
		if status ~= 0 then
			spritex = memory.readbyte(0xE4+slot) + memory.readbyte(0x14E0+slot)*256
			spritey = memory.readbyte(0xD8+slot) + memory.readbyte(0x14D4+slot)*256
			sprites[#sprites+1] = {["x"]=spritex, ["y"]=spritey}
		end
	end		
	return sprites
end

function getExtendedSprites()
	local extended = {}
	for slot=0,11 do
		local number = memory.readbyte(0x170B+slot)
		if number ~= 0 then
			spritex = memory.readbyte(0x171F+slot) + memory.readbyte(0x1733+slot)*256
			spritey = memory.readbyte(0x1715+slot) + memory.readbyte(0x1729+slot)*256
			extended[#extended+1] = {["x"]=spritex, ["y"]=spritey}
		end
	end			
	return extended
end

BoxWidth = 7
BoxHeight = 6
TileSize = 16

function getInputs()
	getPositions()
	
	sprites = getSprites()
	extended = getExtendedSprites()
	
	local inputs = {}
	
	for j=-BoxHeight,BoxHeight,1 do
		row = {}
		for i=-BoxWidth,BoxWidth,1 do
			dx = i*TileSize
			dy = j*TileSize
			row[#row+1] = 0
			
			tile = getTile(dx, dy)
			if tile == 1 and marioY+dy < 0x1B0 then
				row[#row] = 1
			end
			
			for n = 1,#sprites do
				distx = math.abs(sprites[n]["x"] - (marioX+dx))
				disty = math.abs(sprites[n]["y"] - (marioY+dy))
				if distx <= 8 and disty <= 8 then
					row[#row] = -1
				end
			end

			for n = 1,#extended do
				distx = math.abs(extended[n]["x"] - (marioX+dx))
				disty = math.abs(extended[n]["y"] - (marioY+dy))
				if distx < 8 and disty < 8 then
					row[#row] = -1
				end
			end
		end
		inputs[j+BoxHeight] = row
	end
	
	--mariovx = memory.read_s8(0x7B)
	--mariovy = memory.read_s8(0x7D)
	
	return inputs
end
			

Red =   0x80FF0000
Green = 0x8000FF00
Blue =  0x800000FF

function drawMap()
	drawMapBox()
	inputs = {}
	inputs = getInputs()
	for y=0, 2*BoxHeight do
		for x=0, 2*BoxWidth do
			--tile = inputs[(BoxWidth*2+1)*y+x+1]
			tile = inputs[y][x]
			--label(tile, MAP.x + x*16*mapscale, MAP.y + y*16*mapscale, 16*mapscale)
			if tile == 1 then
				drawTerrain(x, y)
			end
			if tile == -1 then
				drawEnemy(x, y)
			end
			
		end
	end
	drawAvatar(BoxWidth+1, BoxHeight+1)
end

function drawMapBox()
	gui.drawBox(MAP.x, MAP.y, MAP.width, MAP.height, 0x00000000,0x80FFFFFF)
end

function drawMapItem(x, y, colour)
	x1 = 2 + MAP.x + tilesize*mapscale*x
	y1 = 2 + MAP.y + tilesize*mapscale*y
	gui.drawBox(x1, y1, x1 + tilesize*mapscale, y1 + tilesize*mapscale, 0x00000000, colour)

end

function drawTerrain(x, y)
	drawMapItem(x, y, Green)
end

function drawEnemy(x, y)
	drawMapItem(x, y, Red)
end

function drawAvatar(x, y)
	drawMapItem(x, y, Blue)
	drawMapItem(x, y-0.5, Blue)
end

while true do
	drawMap()
	label("Game Map", 10, 0, 10)
	emu.frameadvance()
end

