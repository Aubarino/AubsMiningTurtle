-- Store the starting position as a constant (assume (0, 0, 0) facing north)
-- Note: Real position tracking would need GPS or persistent state; this is a placeholder
local origin = { x = 0, y = 0, z = 0 }

-- Function to mine or move down
local function moveOrMineDown()
  if turtle.detectDown() then
    turtle.digDown()
  end
  local moved = turtle.down()
  if not moved then
    print("Blocked! Could not move down.")
    return false
  end
  return true
end

-- Perform 4 moves down
for i = 1, 4 do
  if not moveOrMineDown() then
    print("Movement failed at step " .. i)
    break
  end
end

print("done :)")