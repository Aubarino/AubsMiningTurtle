-- Position and direction tracking
local pos = { x = 0, y = 0, z = 0 }
local dir = 0 -- 0=north, 1=east, 2=south, 3=west
local maxDistance = 16
local downOffset = 16
local ventures = 3
print("version 1a")

local function clamp(val, lower, upper)
    assert(val and lower and upper, "not very useful error message here")
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end

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
  if not success then return false end

  if data.tags then
    for _, tag in ipairs(data.tags) do
      if (tag == "minecraft:unbreakable" or tag == "unbreakable") and tag ~= "minecraft:air" then
        return true
      end
    end
  end

  return false
end

-- Assume these globals exist:
-- pos = {x=0, y=0, z=0}, dir = 0
-- helper functions: tryRefuel(), faceDirection(dir), rightOf(dir), leftOf(dir), dirToVector(dir)

-- Forward declaration
local moveOrMineVecAvoid

-- Main movement + avoidance function
moveOrMineVecAvoid = function(dirVec, preferLevel)
  if not tryRefuel() then return false end

  local function tryMove(dVec)
    if isBlockUnbreakable(dVec) then
      local directions = {
        {x=1, y=0, z=0}, {x=-1, y=0, z=0},
        {x=0, y=0, z=1}, {x=0, y=0, z=-1},
        {x=0, y=1, z=0}, {x=0, y=-1, z=0}
      }
      local idx = math.random(#directions)
      local rndVec = directions[idx]
      return moveOrMineVecAvoid(rndVec)
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
      else return false end

      faceDirection(targetDir)
      if turtle.detect() then turtle.dig() end
      success = turtle.forward()
      if success then
        if dir == 0 then pos.z = pos.z - 1
        elseif dir == 1 then pos.x = pos.x + 1
        elseif dir == 2 then pos.z = pos.z + 1
        elseif dir == 3 then pos.x = pos.x - 1 end
      end
    end
    return success
  end

  -- Attempt direct
  if tryMove(dirVec) then return true end

  -- Horizontal bypass
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

    -- Try vertical detours unless preferLevel is true
    if not preferLevel then
      for _, vert in ipairs({{x=0, y=1, z=0}, {x=0, y=-1, z=0}}) do
        if tryMove(vert) and tryMove(dirVec) then return true end
        tryMove({x=0, y=-vert.y, z=0})
      end
    end

  else
    -- Vertical direction → try horizontal side bypasses
    for _, sideDirFunc in ipairs({rightOf, leftOf}) do
      local sideDir = sideDirFunc(dir)
      local sideVec = dirToVector(sideDir)
      if tryMove(sideVec) and tryMove(dirVec) then return true end
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

function dropNonFuelItemsIntoChest()
  for slot = 1, 16 do
    if turtle.getItemCount(slot) > 0 then
      turtle.select(slot)
      local isFuel = turtle.refuel(0) -- check without consuming
      if not isFuel then
        local item = turtle.getItemDetail(slot)
        local before = item.count
        if turtle.drop() then
          local afterDetail = turtle.getItemDetail(slot)
          local after = afterDetail and afterDetail.count or 0
          if after < before then
            print("Dropped " .. (before - after) .. " of " .. item.name)
          else
            print("Chest could not accept: " .. item.name)
          end
        else
          print("Drop failed for: " .. item.name)
        end
      else
        local item = turtle.getItemDetail(slot)
        print("Kept fuel item: " .. item.name)
      end
    end
  end
  turtle.select(1)
end

function faceNorth()
  while dir ~= 0 do
    turtle.turnLeft()
    dir = (dir - 1) % 4
  end
  print("Now facing North")
end

-- Return to origin (clean and reliable)
local function returnToOrigin()
  print("Returning to origin...")

  while pos.x ~= 0 or pos.z ~= 0 or pos.y ~= 0 do
    if pos.x ~= 0 then
      local step = (pos.x > 0) and -1 or 1
      if not moveOrMineVecAvoid({x=step, y=0, z=0}, true) then
        print("Blocked on X axis")
        sleep(0.1)
      end
    elseif pos.z ~= 0 then
      local step = (pos.z > 0) and -1 or 1
      if not moveOrMineVecAvoid({x=0, y=0, z=step}, true) then
        print("Blocked on Z axis")
        sleep(0.1)
      end
    end
    if pos.y ~= 0 then
      local step = (pos.y > 0) and -1 or 1
      if not moveOrMineVecAvoid({x=0, y=step, z=0}) then
        print("Blocked on Y axis")
        sleep(0.1)
      end
    end
  end

    faceNorth()
  print("Back! :)")
end

-- MAIN MINING THING

print("Starting mining operation...")

local goalYto = (downOffset + math.random(3)) - 1
for i = 1, goalYto do
    if not moveOrMineVecAvoid({x=0, y=-1, z=0}) then
        print("Failed mining down at step " .. i)
        break
    end
end
for ventureCurrent = 0, ventures do
    moveOrMineVecAvoid({x=0, y=-1, z=0})
    local zOffsetGoal = ((math.random() * 2) - 1)
    print(tostring(zOffsetGoal) .. " z")
    for i = 1, clamp((math.random(maxDistance) + 1),0,999) do
        if not moveOrMineVecAvoid({x=0, y=0, z=math.floor(zOffsetGoal)}) then
            print("Failed step " .. i)
            break
        end
    end

    local xOffsetGoal = ((math.random() * 2) - 1)
    print(tostring(xOffsetGoal) .. " x")
    for i = 1, clamp((math.random(maxDistance) + 1),0,999) do
        if not moveOrMineVecAvoid({x=math.floor(zOffsetGoal), y=0, z=0}) then
            print("Failed step " .. i)
            break
        end
    end
end

returnToOrigin()
dropNonFuelItemsIntoChest()

print("Done :)")