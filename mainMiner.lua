-- Store a basic origin (for now just a placeholder)
local origin = { x = 0, y = 0, z = 0 }
local pos = { x = 0, y = 0, z = 0 }
local dir = 0 -- 0=north, 1=east, 2=south, 3=wes

-- Function: Attempt to refuel from inventory
local function tryRefuel()
  if turtle.getFuelLevel() == "unlimited" or turtle.getFuelLevel() > 0 then return true end
  for slot = 1, 16 do
    turtle.select(slot)
    if turtle.refuel(1) then
      print("Refueled using slot " .. slot)
      return true
    end
  end
  print("Out of fuel!")
  return false
end

local function turnRight()
  turtle.turnRight()
  dir = (dir + 1) % 4
end

local function turnLeft()
  turtle.turnLeft()
  dir = (dir + 3) % 4
end

local function faceDirection(targetDir)
  while dir ~= targetDir do
    turnRight()
  end
end

local function moveOrMine(direction)
  if not tryRefuel() then return false end

  local success = false
  if direction == "forward" then
    if turtle.detect() then turtle.dig() end
    success = turtle.forward()
    if success then
      if dir == 0 then pos.z = pos.z - 1
      elseif dir == 1 then pos.x = pos.x + 1
      elseif dir == 2 then pos.z = pos.z + 1
      elseif dir == 3 then pos.x = pos.x - 1 end
    end
  elseif direction == "up" then
    if turtle.detectUp() then turtle.digUp() end
    success = turtle.up()
    if success then pos.y = pos.y + 1 end
  elseif direction == "down" then
    if turtle.detectDown() then turtle.digDown() end
    success = turtle.down()
    if success then pos.y = pos.y - 1 end
  end

  if not success then print("Failed to move " .. direction) end
  return success
end

local function returnToOrigin()
  -- Move in X axis
  if pos.x < 0 then faceDirection(1) -- East
  elseif pos.x > 0 then faceDirection(3) -- West
  end
  while pos.x ~= 0 do moveOrMine("forward") end

  -- Move in Z axis
  if pos.z < 0 then faceDirection(2) -- South
  elseif pos.z > 0 then faceDirection(0) -- North
  end
  while pos.z ~= 0 do moveOrMine("forward") end

  -- Move in Y axis
  while pos.y < 0 do moveOrMine("up") end
  while pos.y > 0 do moveOrMine("down") end

  print("Returned to origin (0, 0, 0)")
end

-- Go down 4 blocks
for i = 1, 4 do
  moveOrMine("down")
end
for i = 1, 2 do
  moveOrMine("forward")
end

-- Go back up to original position
returnToOrigin()
print("Done :)")

print("done :)")