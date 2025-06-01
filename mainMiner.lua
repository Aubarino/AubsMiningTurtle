-- Position and direction
local origin = { x = 0, y = 0, z = 0 }
local pos = { x = 0, y = 0, z = 0 }
local dir = 0 -- still tracked for future usage if needed

-- Vector utilities
local function normalizeAndClampVec(vec)
  local x = math.floor(math.max(-1, math.min(1, vec.x or 0)))
  local y = math.floor(math.max(-1, math.min(1, vec.y or 0)))
  local z = math.floor(math.max(-1, math.min(1, vec.z or 0)))
  return { x = x, y = y, z = z }
end

-- Refuel if needed
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

-- Turn logic (optional but still useful)
local function turnRight() turtle.turnRight(); dir = (dir + 1) % 4 end
local function turnLeft()  turtle.turnLeft(); dir = (dir + 3) % 4 end

-- Move or mine in a direction vector
local function moveOrMineVec(directionVec)
  if not tryRefuel() then return false end

  local dirVec = normalizeAndClampVec(directionVec)
  local success = false

  -- Vertical movement
  if dirVec.y == 1 then
    if turtle.detectUp() then turtle.digUp() end
    success = turtle.up()
    if success then pos.y = pos.y + 1 end
  elseif dirVec.y == -1 then
    if turtle.detectDown() then turtle.digDown() end
    success = turtle.down()
    if success then pos.y = pos.y - 1 end
  -- Horizontal movement
  elseif dirVec.x ~= 0 or dirVec.z ~= 0 then
    -- Determine target facing direction
    local desiredDir = nil
    if dirVec.x == 1 then desiredDir = 1
    elseif dirVec.x == -1 then desiredDir = 3
    elseif dirVec.z == 1 then desiredDir = 2
    elseif dirVec.z == -1 then desiredDir = 0 end

    -- Turn to face desired direction
    while dir ~= desiredDir do
      turnRight()
    end

    if turtle.detect() then turtle.dig() end
    success = turtle.forward()
    if success then
      if dir == 0 then pos.z = pos.z - 1
      elseif dir == 1 then pos.x = pos.x + 1
      elseif dir == 2 then pos.z = pos.z + 1
      elseif dir == 3 then pos.x = pos.x - 1 end
    end
  end

  if not success then
    print("Failed to move in direction: x="..dirVec.x.." y="..dirVec.y.." z="..dirVec.z)
  end

  return success
end

-- Return to origin
local function returnToOrigin()
  -- Move X axis
  while pos.x ~= 0 do
    local dx = (pos.x > 0) and -1 or 1
    moveOrMineVec({ x = dx, y = 0, z = 0 })
  end

  -- Move Z axis
  while pos.z ~= 0 do
    local dz = (pos.z > 0) and -1 or 1
    moveOrMineVec({ x = 0, y = 0, z = dz })
  end

  -- Move Y axis
  while pos.y ~= 0 do
    local dy = (pos.y > 0) and -1 or 1
    moveOrMineVec({ x = 0, y = dy, z = 0 })
  end

  print("Returned to origin (0, 0, 0)")
end

-- Example: go down 4 blocks
for i = 1, 4 do
  moveOrMineVec({ x = 0, y = -1, z = 0 })
end

-- Move forward (north) 2 blocks
for i = 1, 2 do
  moveOrMineVec({ x = 0, y = 0, z = -1 })
end

-- Return to origin
returnToOrigin()
print("Done :)")