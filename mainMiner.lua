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

-- Helper: get direction to the right of current direction (0-3)
local function rightOf(d)
  return (d + 1) % 4
end

-- Helper: get direction to the left of current direction (0-3)
local function leftOf(d)
  return (d + 3) % 4
end

-- Helper: convert direction index to vector {x,z}
local function dirToVector(d)
  if d == 0 then return {x=0, z=-1} -- north
  elseif d == 1 then return {x=1, z=0} -- east
  elseif d == 2 then return {x=0, z=1} -- south
  elseif d == 3 then return {x=-1, z=0} -- west
  end
end

-- Check if block ahead in given direction vector is unbreakable or should be avoided
local function isBlockUnbreakable(directionVector)
  local success, data
  if directionVector.y == 1 then
    success, data = turtle.inspectUp()
  elseif directionVector.y == -1 then
    success, data = turtle.inspectDown()
  else
    success, data = turtle.inspect()
  end
  if not success then
    return false -- no block ahead
  end

  -- Check tags for unbreakable flag
  if data.tags then
    for _, tag in ipairs(data.tags) do
      if tag == "minecraft:unbreakable" or tag == "unbreakable" and tag != "minecraft:air" then
        return true
      end
    end
  end

  -- Check hardness (if available)
  if data.hardness ~= nil and data.hardness < 0 then
    return true
  end

  -- If no harvest tool or level, consider unbreakable
  if data.harvestTool == nil and data.harvestLevel == nil then
    return true
  end

  return false
end

-- Forward declarations
local moveOrMineVecAvoid

-- Dependencies assumed to exist:
-- pos, dir, tryRefuel, isBlockUnbreakable, faceDirection, rightOf, leftOf, dirToVector

-- Define moveOrMineVecAvoid
moveOrMineVecAvoid = function(dirVec)
  if not tryRefuel() then return false end

  local function tryMove(dVec)
    if isBlockUnbreakable(dVec) then
        return false
    end

    local success = false
    if dVec.y == 1 then
      if turtle.detectUp() then turtle.digUp() end
      success = turtle.up()
      if success then pos.y = pos.y + 1 end
    elseif dVec.y == -1 then
      if turtle.detectDown() then turtle.digDown() end
      success = turtle.down()
      if success then pos.y = pos.y - 1 end
    else
      local targetDir
      if dVec.x == 1 then targetDir = 1
      elseif dVec.x == -1 then targetDir = 3
      elseif dVec.z == 1 then targetDir = 2
      elseif dVec.z == -1 then targetDir = 0
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
    return success
  end

  -- Attempt direct move first
  if tryMove(dirVec) then return true end

  -- Horizontal? Try detours
  if dirVec.y == 0 then
    local targetDir
    if dirVec.x == 1 then targetDir = 1
    elseif dirVec.x == -1 then targetDir = 3
    elseif dirVec.z == 1 then targetDir = 2
    elseif dirVec.z == -1 then targetDir = 0 end

    if targetDir then
      for _, sideDirFunc in ipairs({rightOf, leftOf}) do
        local sideDir = sideDirFunc(targetDir)
        local sideVec = dirToVector(sideDir)
        if tryMove(sideVec) and tryMove(dirVec) then
          return true
        end
        -- Backtrack
        faceDirection((sideDir + 2) % 4)
        turtle.back()
        if dir == 0 then pos.z = pos.z + 1
        elseif dir == 1 then pos.x = pos.x - 1
        elseif dir == 2 then pos.z = pos.z - 1
        elseif dir == 3 then pos.x = pos.x + 1 end
      end
    end

    for _, vert in ipairs({{x=0, y=1, z=0}, {x=0, y=-1, z=0}}) do
      if tryMove(vert) and tryMove(dirVec) then
        return true
      end
      -- Move back if second try failed
      tryMove({x=0, y=-vert.y, z=0})
    end

  else
    -- Vertical? Try side bypasses
    for _, sideDirFunc in ipairs({rightOf, leftOf}) do
      local sideDir = sideDirFunc(dir)
      local sideVec = dirToVector(sideDir)
      if tryMove(sideVec) and tryMove(dirVec) then
        return true
      end
      -- Backtrack
      faceDirection((sideDir + 2) % 4)
      turtle.back()
      if dir == 0 then pos.z = pos.z + 1
      elseif dir == 1 then pos.x = pos.x - 1
      elseif dir == 2 then pos.z = pos.z - 1
      elseif dir == 3 then pos.x = pos.x + 1 end
    end
  end

  print("All bypass attempts failed for", dirVec.x, dirVec.y, dirVec.z)
  return false
end

-- Return to origin (0,0,0) by moving horizontally first, then vertically
local function returnToOrigin()
  print("Returning to origin...")
  while pos.x ~= 0 do
    local step = (pos.x > 0) and -1 or 1
    if not moveOrMineVecAvoid({x=step, y=0, z=0}) then
      print("Blocked on X axis return")
      break
    end
  end
  while pos.z ~= 0 do
    local step = (pos.z > 0) and -1 or 1
    if not moveOrMineVecAvoid({x=0, y=0, z=step}) then
      print("Blocked on Z axis return")
      break
    end
  end
  while pos.y ~= 0 do
    local step = (pos.y > 0) and -1 or 1
    if not moveOrMineVecAvoid({x=0, y=step, z=0}) then
      print("Blocked on Y axis return")
      break
    end
  end
  print("Returned to origin (0,0,0)")
end

-- MAIN MINING THING

print("Starting mining operation...")

for i = 1, 4 do
  if not moveOrMineVecAvoid({x=0, y=-1, z=0}) then
    print("Failed mining down at step " .. i)
    break
  end
end

for i = 1, 2 do
  if not moveOrMineVecAvoid({x=0, y=0, z=1}) then
    print("Failed moving forward at step " .. i)
    break
  end
end

returnToOrigin()

print("Done :)")