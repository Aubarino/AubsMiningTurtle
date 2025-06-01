-- Store a basic origin (for now just a placeholder)
local origin = { x = 0, y = 0, z = 0 }

-- Function: Attempt to refuel from inventory
local function tryRefuel()
  for slot = 1, 16 do
    turtle.select(slot)
    local item = turtle.getItemDetail()
    if item then
      print("Checking slot " .. slot .. ": " .. item.name)
      if turtle.refuel(1) then
        print("Refueled using " .. item.name .. " from slot " .. slot)
        return true
      end
    end
  end
  print("No usable fuel found. Insert coal or other fuel.")
  return false
end

-- Function: Move or mine down
local function moveOrMineDown()
  if turtle.getFuelLevel() == 0 then
    print("Out of fuel! Attempting to refuel...")
    if not tryRefuel() then
      return false
    end
  end

  if turtle.detectDown() then
    print("Block detected below. Digging...")
    if not turtle.digDown() then
      print("digDown failed! Block might be unbreakable.")
      return false
    end
  else
    print("No block below. Attempting to move down.")
  end

  if not turtle.down() then
    print("Move failed. Something is still in the way.")
    return false
  end

  return true
end

-- Main loop: go 4 blocks down
for i = 1, 4 do
  print("Step " .. i)
  if not moveOrMineDown() then
    print("Stopping at step " .. i .. " due to error.")
    break
  end
end

print("done :)")