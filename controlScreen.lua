-- controlScreen.lua
-- full executon thing is wget run https://raw.githubusercontent.com/Aubarino/AubsMiningTurtle/refs/heads/main/controlScreen.lua

-- Setup
local origin = {x = 0, z = 0} -- your base reference point
local turtles = {}
local stopSignal = false
rednet.open("back") -- or side of the modem
local input = ""
local lineGoal = 1

-- Optional monitor support
local mon = peripheral.wrap("left")
if mon then mon.setTextScale(0.5) end
print("Status : ONLINE")
print("version d")
if not mon then
    print("Monitor not found!")
    return
end

local function draw()
    for id, turt in pairs(turtles) do
        local relX = turt.x - origin.x
        local relZ = turt.z - origin.z
        local relY = turt.y
        lineGoal = lineGoal + 1
        mon.setCursorPos(1, lineGoal)
        mon.write(id .. ": X=" .. relX .. " Y=" .. relY .. " Z=" .. relZ .. " | "..turt.status)
    end

    local w, h = mon.getSize()
    local squareSize = 2
    for id, turt in pairs(turtles) do
        local relX = (turt.glX + turt.x - 650) * 0.5
        local relZ = (turt.glZ + turt.z - 379) * 0.5

        local startX = (math.floor((w - squareSize) / 2) + 1) + relX
        local startY = (math.floor((h - squareSize) / 2) + 1) + relZ
        mon.setBackgroundColor(colors.red)

        for y = 0, squareSize - 1 do
            mon.setCursorPos(startX, startY + y)
            mon.write(string.rep(" ", squareSize))  -- space with red background = red "pixel"
        end
    end
    mon.setBackgroundColor(colors.black)  -- reset background
end

-- Listen for position updates
while true do
    local _, message, protocol = rednet.receive("turtlePosData")
    mon.clear()
    mon.setBackgroundColor(colors.black)
    mon.setCursorPos(1, 1)
    mon.write("Aub turtle HQ")
    mon.setCursorPos(1, 2)
    mon.write("Status : ONLINE "..#turtles)
    lineGoal = 2
    if type(message) == "table" and message.id then
        turtles[message.id] = {x = message.x, y = message.y, z = message.z, glX = message.glX, glY = message.glY, glZ = message.glZ, status = message.status}
        draw()
    end
    -- input = read()
    -- if (input == "end") then
    --     stopSignal = true
    -- end
    sleep(0.25)
end

print("ended")
mon.clear()
mon.setCursorPos(1, 1)
mon.write("Aub turtle HQ | Status : OFFLINE")
print("Status : OFFLINE")