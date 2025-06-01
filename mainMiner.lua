-- Make sure turtle has a pickaxe upgrade (mining turtle)
if turtle.detectDown() then
  turtle.digDown()
end

-- Move down into the mined space
if turtle.down() then
  print("Moved down 1 block.")
else
  print("Could not move down.")
end