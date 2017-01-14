function label(text, x, y, size)
	aspect = 0.65
	width = string.len(text)*size*aspect
	gui.drawBox(x, y, x+width,y+size,0x00000000,0x80FF0000)
	gui.drawText(x, y, text, 0xFF000000, size)

end

marioheight = 32
mariowidth = 16
mapscale = 0.4

function mariobox(x, y)
	gui.drawBox(x, y, x+15*mapscale,y+35*mapscale,0x00000000,0x8000FF00)
end

function box(text, x, y, size)
	label(text, x, y+size/2, size)
end

RAM = {
	marioX = 0xD1,
	marioY = 0xD3,
	layer1x = 0x1A,
	layer1y = 0x1C
}

MAP = {
	x = 0,
	width = 255*mapscale,
	y = 0,
	height = 255*mapscale
}

function getPositions()
		marioX = memory.read_s16_le(RAM.marioX)
		marioY = memory.read_s16_le(RAM.marioY)
		label("M", marioX, 10, 10)
		local layer1x = memory.read_s16_le(RAM.layer1x);
		local layer1y = memory.read_s16_le(RAM.layer1y);
		
		screenX = marioX-layer1x
		screenY = marioY-layer1y

		mapX = screenX/255 * MAP.width + MAP.x
		mapY = screenY/255 * MAP.height + MAP.y
		--mariobox(mapX, mapY)

end

function getTile(dx, dy)
	x = math.floor((marioX+dx+8)/16)
	y = math.floor((marioY+dy)/16)
	
	return memory.readbyte(0x1C800 + math.floor(x/0x10)*0x1B0 + y*0x10 + x%0x10)	
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

BoxRadius = 6

function getInputs()
	getPositions()
	
	sprites = getSprites()
	extended = getExtendedSprites()
	
	local inputs = {}
	
	for dy=-BoxRadius*16,BoxRadius*16,16 do
		for dx=-BoxRadius*16,BoxRadius*16,16 do
			inputs[#inputs+1] = 0
			
			tile = getTile(dx, dy)
			if tile == 1 and marioY+dy < 0x1B0 then
				inputs[#inputs] = 1
			end
			
			for i = 1,#sprites do
				distx = math.abs(sprites[i]["x"] - (marioX+dx))
				disty = math.abs(sprites[i]["y"] - (marioY+dy))
				if distx <= 8 and disty <= 8 then
					inputs[#inputs] = -1
				end
			end

			for i = 1,#extended do
				distx = math.abs(extended[i]["x"] - (marioX+dx))
				disty = math.abs(extended[i]["y"] - (marioY+dy))
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
			
function readlocation(x, y)
	x = math.floor(x)
	y = math.floor(y)
	return memory.readbyte(0x1C800 + math.floor(x/0x10)*0x1B0 + y*0x10 + x%0x10)

end

function drawMap()
	gui.drawBox(MAP.x, MAP.y, MAP.width, MAP.height, 0x00000000,0x80FFFFFF)
	--mariobox(mapX, mapY)
	inputs = {}
	inputs = getInputs()
	gridsize = 12
	for y=0, gridsize do
		for x=0, gridsize do
			tile = inputs[13*y+x+1]
			--label(tile, MAP.x + x*16*mapscale, MAP.y + y*16*mapscale, 16*mapscale)
			if tile == 1 then
				drawTerrain(x, y)
			end
			if tile == -1 then
				drawEnemy(x, y)
			end
			
		end
	end
	drawAvatar(gridsize/2, gridsize/2+1)
end

tilesize = 16

function drawTerrain(x, y)
	x1 = MAP.x + tilesize*mapscale*x
	y1 = MAP.y + tilesize*mapscale*y
	gui.drawBox(x1, y1, x1 + tilesize*mapscale, y1 + tilesize*mapscale, 0x00000000,0x800000FF)
end

function drawEnemy(x, y)
	x1 = MAP.x + tilesize*mapscale*x
	y1 = MAP.y + tilesize*mapscale*y
	gui.drawBox(x1, y1, x1 + tilesize*mapscale, y1 + tilesize*mapscale, 0x00000000,0x80FF0000)
end

function drawAvatar(x, y)
	x1 = MAP.x + tilesize*mapscale*x
	y1 = MAP.y + tilesize*mapscale*y
	gui.drawBox(x1, y1, x1 + tilesize*mapscale, y1 + tilesize*mapscale, 0x00000000,0x8000FF00)
end

while true do
	getPositions()
	drawMap()
	label("Game Map", 10, 0, 10)
	emu.frameadvance()
end

