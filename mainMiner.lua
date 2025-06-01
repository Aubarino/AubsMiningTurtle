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

-- Check if block is unbreakable or should be avoided
local function isBlockUnbreakable()
  local success, data = turtle.inspect()
  if not success then
    -- No block ahead, so no block to be unbreakable
    return false
  end

  -- Check if block has 'tags' and if it includes 'minecraft:unbreakable' or similar
  if data.tags then
    for _, tag in ipairs(data.tags) do
      if tag == "minecraft:unbreakable" or tag == "unbreakable" then
        return true
      end
    end
  end

  -- Check hardness (if available)
  -- Blocks with hardness <= 0 might be unbreakable or instant break (like air)
  if data.hardness ~= nil then
    if data.hardness < 0 then
      return true
    end
  end

  -- Check if the block is harvestable (some mods may have this info)
  -- If the block cannot be harvested (digged), treat it as unbreakable
  if data.harvestTool == nil and data.harvestLevel == nil then
    -- No harvest tool or level means likely unbreakable or special block
    return true
  end

  -- If none of the above flags it, assume breakable
  return false
end

-- Attempt to move or mine with obstacle avoidance (go around to right if blocked)
local function moveOrMineVecWithAvoid(dirVec)
  -- Attempt to move/mine in dirVec, with wall-following obstacle avoidance to the right

  -- Helper: move forward one block, return success boolean
  local function tryForward()
    if not tryRefuel() then return false end
    if turtle.detect() then
      if isBlockUnbreakable() then return false end
      turtle.dig()
    end
    local success = turtle.forward()
    if success then
      if dir == 0 then pos.z = pos.z - 1
      elseif dir == 1 then pos.x = pos.x + 1
      elseif dir == 2 then pos.z = pos.z + 1
      elseif dir == 3 then pos.x = pos.x - 1 end
    end
    return success
  end

  -- Determine horizontal movement only for obstacle avoidance (y must be 0)
  if dirVec.y ~= 0 then
    -- No horizontal obstacle avoidance for vertical moves, just moveOrMineVec directly
    if dirVec.y == 1 then
      if turtle.detectUp() then turtle.digUp() end
      if turtle.up() then pos.y = pos.y + 1 return true else return false end
    elseif dirVec.y == -1 then
      if turtle.detectDown() then turtle.digDown() end
      if turtle.down() then pos.y = pos.y - 1 return true else return false end
    end
    return false -- Shouldn't reach here
  end

  -- Calculate targetDir from dirVec (only x or z axis)
  local targetDir = nil
  if dirVec.x == 1 then targetDir = 1
  elseif dirVec.x == -1 then targetDir = 3
  elseif dirVec.z == 1 then targetDir = 2
  elseif dirVec.z == -1 then targetDir = 0
  else
    print("Invalid horizontal move vector in avoidance")
    return false
  end

  faceDirection(targetDir)

  -- Try to move forward normally first
  if tryForward() then return true end

  -- Blocked or unbreakable -> try to go around to right
  turnRight()
  if tryForward() then
    turnLeft()
    if tryForward() then
      return true
    else
      -- Can't move forward after going right; try left side recovery
      turnLeft()
      if tryForward() then
        turnRight()
        return true
      else
        -- Stuck
        turnRight() -- restore original facing
        return false
      end
    end
  else
    -- Can't move right either, try going left instead
    turnLeft()
    turnLeft() -- turned 180 from original
    if tryForward() then
      turnRight()
      if tryForward() then
        return true
      else
        turnRight()
        return false
      end
    else
      -- No options
      turnRight() -- restore facing original
      return false
    end
  end
end

-- Original moveOrMineVec, renamed for internal use without avoidance
local function moveOrMineVec(dirVec)
  if not tryRefuel() then return false end
  local success = false

  if dirVec.y == 1 then
    if turtle.detectUp() then turtle.digUp() end
    success = turtle.up()
    if success then pos.y = pos.y + 1 end
  elseif dirVec.y == -1 then
    if turtle.detectDown() then turtle.digDown() end
    success = turtle.down()
    if success then pos.y = pos.y - 1 end
  else
    local targetDir = nil
    if dirVec.x == 1 then targetDir = 1
    elseif dirVec.x == -1 then targetDir = 3
    elseif dirVec.z == 1 then targetDir = 2
    elseif dirVec.z == -1 then targetDir = 0
    else
      print("Invalid horizontal move vector")
      return false
    end
    faceDirection(targetDir)
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

-- Path to specific position relative to origin, bias X and Z first, then Y
local function moveToPos(targetPos)
  -- Move in X axis
  while pos.x ~= targetPos.x do
    local step = (pos.x < targetPos.x) and 1 or -1
    if not moveOrMineVecWithAvoid({x=step, y=0, z=0}) then
      print("Blocked on X axis moving to position")
      return false
    end
  end
  -- Move in Z axis
  while pos.z ~= targetPos.z do
    local step = (pos.z < targetPos.z) and 1 or -1
    if not moveOrMineVecWithAvoid({x=0, y=0, z=step}) then
      print("Blocked on Z axis moving to position")
      return false
    end
  end
  -- Move in Y axis
  while pos.y ~= targetPos.y do
    local step = (pos.y < targetPos.y) and 1 or -1
    if not moveOrMineVecWithAvoid({x=0, y=step, z=0}) then
      print("Blocked on Y axis moving to position")
      return false
    end
  end
  return true
end

-- Return to origin (0,0,0) by moving horizontally first, then vertically
local function returnToOrigin()
  return moveToPos({x=0, y=0, z=0})
end

-- MAIN MINING THING

print("Starting mining operation...")

for i = 1, 4 do
  if not moveOrMineVecWithAvoid({x=0, y=-1, z=0}) then
    print("Failed mining down at step " .. i)
    break
  end
end

for i = 1, 2 do
  if not moveOrMineVecWithAvoid({x=0, y=0, z=1}) then
    print("Failed moving forward at step " .. i)
    break
  end
end

returnToOrigin()

print("Done :)")