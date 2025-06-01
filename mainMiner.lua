-- Position and direction tracking
local pos = { x = 0, y = 0, z = 0 }
local dir = 0 -- 0=north, 1=east, 2=south, 3=west

-- Attempt to refuel from inventory if needed
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

-- Turn turtle right and update direction
local function turnRight()
  turtle.turnRight()
  dir = (dir + 1) % 4
end

-- Turn turtle left and update direction
local function turnLeft()
  turtle.turnLeft()
  dir = (dir + 3) % 4
end

-- Turn turtle to face a target direction (0-3)
local function faceDirection(targetDir)
  while dir ~= targetDir do
    turnRight()
  end
end

-- Calibrate direction by forcibly setting dir=0 (north)
-- Assumes turtle starts facing an unknown direction
-- For better calibration, user must manually face north before running
local function orientNorth()
  -- Since no compass, we just reset dir to 0 and rely on user facing north
  print("Please face NORTH before starting the program.")
  print("Press any key to continue...")
  os.pullEvent("key") -- wait for any keypress
  dir = 0
end

-- Move or mine in a 3D direction vector {x,y,z} where each component is -1,0, or 1
-- Moves only one block in that direction
local function moveOrMineVec(dirVec)
  if not tryRefuel() then return false end
  local success = false

  -- Vertical movement (y axis)
  if dirVec.y == 1 then
    if turtle.detectUp() then turtle.digUp() end
    success = turtle.up()
    if success then pos.y = pos.y + 1 end
  elseif dirVec.y == -1 then
    if turtle.detectDown() then turtle.digDown() end
    success = turtle.down()
    if success then pos.y = pos.y - 1 end
  else
    -- Horizontal movement: x and z
    -- Determine target direction from vector (only one axis at a time)
    local targetDir = nil
    if dirVec.x == 1 then targetDir = 1 -- east
    elseif dirVec.x == -1 then targetDir = 3 -- west
    elseif dirVec.z == 1 then targetDir = 2 -- south
    elseif dirVec.z == -1 then targetDir = 0 -- north
    else
      print("Invalid horizontal move vector")
      return false
    end

    -- Face the target direction
    faceDirection(targetDir)

    -- If block detected, dig it
    if turtle.detect() then turtle.dig() end

    success = turtle.forward()
    if success then
      if dir == 0 then pos.z = pos.z - 1
      elseif dir == 1 then pos.x = pos.x + 1
      elseif dir == 2 then pos.z = pos.z + 1
      elseif dir == 3 then pos.x = pos.x - 1
      end
    end
  end

  if not success then print("Failed to move/mine in direction: ", dirVec.x, dirVec.y, dirVec.z) end
  return success
end

-- Return to origin (0,0,0) by moving horizontally first, then vertically
local function returnToOrigin()
  print("Returning to origin...")
  -- Move in X axis
  while pos.x ~= 0 do
    local step = (pos.x > 0) and -1 or 1
    if not moveOrMineVec({x=step, y=0, z=0}) then
      print("Blocked on X axis return")
      break
    end
  end
  -- Move in Z axis
  while pos.z ~= 0 do
    local step = (pos.z > 0) and -1 or 1
    if not moveOrMineVec({x=0, y=0, z=step}) then
      print("Blocked on Z axis return")
      break
    end
  end
  -- Move in Y axis (vertical)
  while pos.y ~= 0 do
    local step = (pos.y > 0) and -1 or 1
    if not moveOrMineVec({x=0, y=step, z=0}) then
      print("Blocked on Y axis return")
      break
    end
  end
  print("Returned to origin (0,0,0)")
end

-- MAIN PROGRAM --

orientNorth()

-- Example task: mine down 4 blocks directly below, then move forward 2 blocks, then return
print("Starting mining operation...")

for i = 1, 4 do
  if not moveOrMineVec({x=0, y=-1, z=0}) then
    print("Failed mining down at step " .. i)
    break
  end
end

for i = 1, 2 do
  if not moveOrMineVec({x=0, y=0, z=1}) then
    print("Failed moving forward at step " .. i)
    break
  end
end

returnToOrigin()

print("Done :)")