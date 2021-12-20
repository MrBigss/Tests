if not turtle then
	printError("Requires a Turtle")
	return
end


-- Just clear the screen and reposition at top of screen.
local function clearScreen()
	term.clear()
	term.setCursorPos(1,1)
end


-- Try to dig in front. Keep digging until there's nothing anymore (for falling blocks)
local function tryDig()
	while turtle.detect() do
		if turtle.dig() then
			sleep(0.5)
		else
			return false
		end
	end
	return true
end


-- Try to dig up. Keep digging until there's nothing anymore (for falling blocks)
local function tryDigUp()
	while turtle.detectUp() do
		if turtle.digUp() then
			sleep(0.5)
		else
			return false
		end
	end
	return true
end


-- Try to dig down. Keep digging until there's nothing anymore (for falling blocks? I don't know, but whatever, in case of cobble gen I guess.)
local function tryDigDown()
	while turtle.detectDown() do
		if turtle.digDown() then
			sleep(0.5)
		else
			return false
		end
	end
	return true
end


-- Refuel the turtle, when you need to refuel it.
local function refuelFromAnySlot()
	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel == "unlimited" or fuelLevel > 0 then
		return
	end
	
	local function tryRefuel()
		for n = 1, 16 do
			if turtle.getItemCount(n) > 0 then
				turtle.select(n)
				if turtle.refuel(1) then
					turtle.select(1)
					return true
				end
			end
		end
		turtle.select(1)
		return false
	end
	
	if not tryRefuel() then
		print("Add more fuel to continue.")
		while not tryRefuel() do
			os.pullEvent("turtle_inventory")
		end
		print("Resuming process.")
	end
end


-- Refuel the turtle, from a specific slot, until a minimum amount. (Charcoal = 80)
local function refuelFromSlot(slot, minAmount)
	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel == "unlimited" or fuelLevel >= minAmount then
		print("Fuel level.........................[OK]")
		return true
	end
	
	local function tryRefuel() -- Try to refuel from a slot, leaving one item in it at all time.
		if turtle.getItemCount(slot) > 1 then
			turtle.select(slot)
			if turtle.refuel(1) then return true end
		end
		return false
	end
	
	while turtle.getFuelLevel() < minAmount do
		if not tryRefuel() then
			print("Add more charcoal to slot " .. slot .. " to continue.")
			while not tryRefuel() do
				os.pullEvent("turtle_inventory")
			end
		end
	end
	print("Fuel level.........................[OK]")
	return true
end


-- Try to move up. If it can't, do stuff to try and clear the way to be able to move up.
local function tryUp()
	while not turtle.up() do
		if turtle.detectUp() then
			if not tryDigUp() then
				return false
			end
		elseif turtle.attackUp() then
		else
			sleep(0.5)
		end
	end
	return true
end


-- Try to move down. If it can't, do stuff to try and clear the way to be able to move down.
local function tryDown()
	while not turtle.down() do
		if turtle.detectDown() then
			if not tryDigDown() then
				return false
			end
		elseif turtle.attackDown() then
		else
			sleep(0.5)
		end
	end
	return true
end


-- Try to move forward. If it can't, do stuff to try and clear the way to be able to move forward.
local function tryForward()
	while not turtle.forward() do
		if turtle.detect() then
			if not tryDig() then
				return false
			end
		elseif turtle.attack() then
		else
			sleep(0.5)
		end
	end
	return true
end


-- Check if a minimum number of a specific item is in a specific slot.
local function checkItemInSlot(slot, itemName, minCount)
	local function printRequirements()
		print("Put " .. minCount .. " of\n  " .. itemName .. "\nin slot " .. slot .. " to continue")
	end
	
	
	local item = turtle.getItemDetail(slot)
	if not item then
		clearScreen()
		print ("Did not find\n  " .. itemName .. "\nin slot " .. slot .. ".\n\nSlot is empty.\n")
		printRequirements()
		return false
	end

	if item.name ~= itemName then
		clearScreen()
		print ("Did not find\n  " .. itemName .. "\nin slot " .. slot .. ".\n\nInstead was\n  " .. item.name .. "\n")
		printRequirements()
		return false
	end
	
	if item.count < minCount then
		clearScreen()
		print ("Did not find at least " .. minCount .. "\n  " .. itemName .. "\nin slot " .. slot .. ".\n")
		printRequirements()
		return false
	end
	
	-- All checks passed.
	return true
end


-- Check for the prerequisites before going.
-- minecraft:spruce_sapling 2, slot 1
-- minecraft:charcoal 2, slot 2
local function checkInventory()
	local inventoryOk = false -- Just to make sure someone won't remove stuff from slot 1 after it's validated.
	
	while not inventoryOk do
		inventoryOk = true
		-- Check for 2 spruce sapplings in slot 1
		while not checkItemInSlot(1, "minecraft:spruce_sapling", 2) do
			inventoryOk = false
			os.pullEvent("turtle_inventory")
		end
			
		-- Check for 2 charcoal in slot 2
		while not checkItemInSlot(2, "minecraft:charcoal", 2) do
			inventoryOk = false
			os.pullEvent("turtle_inventory")
		end
	end
	print("Inventory prerequisites............[OK]")
end

-- Plant a sappling in front of the turtle if not present.
local function plantSappling()
	turtle.select(1) -- Select sappling slot.
	-- If there is something, either continue if a sappling, or destroy and replant is not.
	while turtle.detect() do
		if turtle.compare() then return true end -- If there's already a sappling, don't do anything, just go.
		tryDig()
	end
	
	while not turtle.place() do
		print("Help, turtle could not place a sappling!!")
	end
end

-- Suck things from the front, then left, then look at front again. Turning doesn't use fuel.
local function suckFrontLeftAndRight()
	sleep(0.5)
	turtle.suck() 
	turtle.turnRight()
	sleep(0.1)
	turtle.suck()
	turtle.turnLeft()
	turtle.turnLeft()
	sleep(0.1)
	turtle.suck()
	turtle.turnRight()
	sleep(0.1)
end

-- Go around where the tree base was, and suck the sapplings into the turtle.
local function suckSapplingsRun()
	turtle.turnRight()
	tryForward()
	suckFrontLeftAndRight()
	turtle.turnLeft()
	tryForward() suckFrontLeftAndRight()
	tryForward() suckFrontLeftAndRight()
	turtle.turnLeft()
	tryForward() suckFrontLeftAndRight()
	tryForward() suckFrontLeftAndRight()
	turtle.turnLeft()
	tryForward() suckFrontLeftAndRight()
	tryForward() suckFrontLeftAndRight()
	turtle.turnLeft()
	tryForward() -- Don't suck, next to chest
	turtle.turnLeft()
end


-- Dump almost everything in chest behind turtle
local function dumpToChest()
	turtle.turnRight()
	turtle.turnRight()
	
	-- Drop all items from all slots except the fuel and sappling.
	for n = 3, 16 do
		turtle.select(n)
		while not turtle.drop() and turtle.getItemCount(n) > 0 do
			print("Not enough free space in chest..[ERROR]")
			sleep(5.0)
		end
	end
	turtle.turnRight()
	turtle.turnRight()
end

--Suck from the chest below, until we have at least 8 charcoal.
local function getFuelFromChestUnder()
	turtle.select(2)
	local charcoalNeededCount = 8 - turtle.getItemCount(2)
	if charcoalNeededCount > 0 then 
		turtle.suckDown(charcoalNeededCount)
	end
end

-- ------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------------
-- Main block
-- ------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------------
-- Lumber turtle algorithm.
-- Required before it can work:
--   At least one spruce sappling in the first slot.
--   At least one spruce log in the second slot.
--   At least one charcoal in the third slot.
-- Start on ground. Move up one, and monitor if a spruce has grown. (Don't bother with other tree, they're anoying to manage. Or make less wood.)
-- When detected, move down, then start breaking trunk. "Go up, detect, break, until no detect".
-- Then go back to ground, turn around, and put in chest. Turn around, restart loop.

local cycle = 1
local doCycle = true



while doCycle do
	clearScreen()

	cycle = cycle % 1000000000 -- I'd rather not have the format break.
	local cycleString = string.format("=== Get the choppa, cycle %09d ===", cycle)
	print(cycleString)
	sleep(5.0) -- General sleeping. This is not a high performance program, just give some breathing room to the server in case of fast loops.
	checkInventory()
	refuelFromSlot(2, 200)

	print("Resetting to ground................[OK]")
	while turtle.down() do end --Go down until hitting floor.
	
	print("Planting sappling..................[OK]")
	plantSappling()
	
	print("Monitoring tree growth.............[OK]")
	tryUp()
	while not turtle.detect() do sleep(5.0) end --Wait for tree growth
	print("Tree detected, chopping started....[OK]")
	tryDown() -- Position at the base of tree.
	
	
	-- Do the actual chopping. Chop, move up, detect, repeat.
	local treeDone = false
	local turtleHeight = 0
	while not treeDone do
		tryDig()
		tryUp()
		turtleHeight = turtleHeight + 1
		if not turtle.detect() then treeDone = true end
	end
	
	print("Tree choppin done, coming down.....[OK]")
	for n = 1, turtleHeight do
		tryDown()
	end
	
	sleep(5.0) -- Wait for fast leaf decay to break all leaves. (Increase in case of normal minecraft)
	
	print("Going around to suck sappling......[OK]")
	suckSapplingsRun()
	
	print("Putting crap in the chest behind...[OK]")
	dumpToChest()
	
	print("Try to get fuel from chest below...[OK]")
	getFuelFromChestUnder()
	
	cycle = cycle + 1
	print("End of tree chopping cycle.........[OK]")
	sleep(5.0) -- General sleeping. This is not a high performance program, just give some breathing room to the server in case of loop.
end
