-- Store starting position (placeholder)
local origin = { x = 0, y = 0, z = 0 }

-- Ensure turtle has fuel
if turtle.getFuelLevel() == 0 then
  print("No fuel! Insert fuel and run again.")
  return
end

-- Function to mine or move down
local function moveOrMineDown()
  if turtle.detectDown() then
    print("Block detected below. Digging...")
    local success = turtle.digDown()
    if not success then
      print("digDown failed! Block might be unbreakable.")
      return false
    end
  else
    print("No block below. Attempting to move down.")
  end

  local moved = turtle.down()
  if not moved then
    print("turtle.down() failed. Possible reasons:")
    print("- Something still below (entity, item, unbreakable block)")
    print("- No fuel")
    print("- Claimed/protected area")
    return false
  end

  return true
end

-- Perform 4 moves down
for i = 1, 4 do
  print("Step " .. i)
  if not moveOrMineDown() then
    print("Movement failed at step " .. i)
    break
  end
end

print("done :)")