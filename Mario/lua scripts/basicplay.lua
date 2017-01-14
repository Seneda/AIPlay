console.writeline("Hello Mario World")

-- This is just a basic test script to check that buttons can be pressed in the Super Mario SNES game.
-- Start script with the game in any state within a level.
-- This cript just makes mario move right and keep jumping.

ButtonNames = {
	"A",
	"B",
	"X",
	"Y",
	"Up",
	"Down",
	"Left",
	"Right",
}

maxjump = 10 -- Empirically tested

frametimer = 0
jumptimer = 0

jumpstart = false

while true do
	--console.writeline("Move right")
	controller = {};
	controller["P1 Right"] = true
	if frametimer % 10 == 0 then
		console.writeline(frametimer)
	end
	if frametimer % 20 == 0 then
		jumpstart = true
		jumptimer = 0
	end
	
	-- Jump Controller
	if jumpstart then
		controller["P1 B"] = true
		jumptimer = jumptimer + 1
		if jumptimer > maxjump then
			jumpstart = false
		end
	end
	frametimer = frametimer + 1
	joypad.set(controller)
	emu.frameadvance();
end
