-- controlScreen.lua
-- full executon thing is wget run https://raw.githubusercontent.com/Aubarino/AubsMiningTurtle/refs/heads/main/controlScreen.lua

-- Setup
local origin = {x = 0, z = 0} -- your base reference point
local turtles = {}
local stopSignal = false
rednet.open("back") -- or side of the modem
local input = ""
local lineGoal = 1

local gradientColors = {
    colors.red,
    colors.orange,
    colors.yellow,
    colors.lime,
    colors.green,
    colors.cyan,
    colors.blue,
    colors.purple
}

-- Optional monitor support
local mon = peripheral.wrap("left")
if mon then mon.setTextScale(0.5) end
print("Status : ONLINE")
print("version e")
if not mon then
    print("Monitor not found!")
    return
end

local function draw()
    mon.clear()
    mon.setCursorPos(1, 1)
    mon.write("Aub Turtle HQ (version e)\n")
    lineGoal = 3

    -- Convert turtles to a sorted list to get consistent color order
    local sortedIDs = {}
    for id in pairs(turtles) do table.insert(sortedIDs, id) end
    table.sort(sortedIDs)

    -- Draw text lines with color
    for i, id in ipairs(sortedIDs) do
        local turt = turtles[id]
        local relX = turt.x - origin.x
        local relZ = turt.z - origin.z
        local relY = turt.y

        local color = gradientColors[((i - 1) % #gradientColors) + 1]
        mon.setCursorPos(1, lineGoal)
        mon.setBackgroundColor(color)
        mon.write(id .. ": X=" .. relX .. " Y=" .. relY .. " Z=" .. relZ .. " | " .. (turt.status or ""))
        lineGoal = lineGoal + 1
    end

    -- Draw map squares
    local w, h = mon.getSize()
    local squareSize = 2

    for i, id in ipairs(sortedIDs) do
        local turt = turtles[id]
        local color = gradientColors[((i - 1) % #gradientColors) + 1]

        local relX = (turt.glX + turt.x - 650) * 0.5
        local relZ = (turt.glZ + turt.z - 379) * 0.5

        local startX = math.floor((w - squareSize) / 2 + 1 + relX)
        local startY = math.floor((h - squareSize) / 2 + 1 + relZ)

        mon.setBackgroundColor(color)
        for y = 0, squareSize - 1 do
            mon.setCursorPos(startX, startY + y)
            mon.write(string.rep(" ", squareSize))
        end
    end

    mon.setBackgroundColor(colors.black) -- Reset background
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