-- controlScreen.lua
-- full execution: wget run https://raw.githubusercontent.com/Aubarino/AubsMiningTurtle/refs/heads/main/controlScreen.lua

-- Setup
local origin = {x = 0, z = 0}
local turtles = {}
local trails = {}
local trailIdToSet = 0
local stopSignal = false
local globalStartPos {x = 0, y = 0, z = 0}
rednet.open("back")
local input = ""
local lineGoal = 1
VERSION = "X"

local gradientColors = {
    colors.red, colors.orange, colors.yellow, colors.lime,
    colors.green, colors.cyan, colors.blue, colors.purple
}
local gradientShades = {
    colors.white, colors.lightGray, colors.lightGray, colors.gray
}

-- Monitor setup
local mon = peripheral.wrap("left")
if mon then
    mon.setTextScale(0.5)
    mon.setTextColor(colors.white)
end
print("Status : ONLINE")
print("version "..VERSION)
if not mon then
    print("Monitor not found!")
    return
end

print("Enter average turtle origin pos : x y z")
local input = read()

-- Split input string into x, y, z
local xStr, yStr, zStr = input:match("^(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)$")
if not xStr then
    print("Invalid input. Please enter three space-separated numbers.")
    return
end
globalStartPos = {
    x = tonumber(xStr),
    y = tonumber(yStr),
    z = tonumber(zStr)
}

local function draw()
    mon.clear()
    mon.setTextColor(colors.white)
    mon.setBackgroundColor(colors.black)
    mon.setCursorPos(1, 1)

    local sortedIDs = {}
    for id in pairs(turtles) do table.insert(sortedIDs, id) end
    table.sort(sortedIDs)

    local w, h = mon.getSize()
    local squareSize = 1

    for i, trail in ipairs(trails) do
        local color = gradientShades[math.max(math.min(math.floor(((math.min(math.abs(trail.y),1) / 16) * 3) + 1),1),4)]

        -- Increase scaling to 0.5 or 1 so it spreads nicely on monitor
        local relX = trail.x * 0.2
        local relZ = trail.z * 0.2

        local startX = math.floor((w - squareSize) / 2 + 1 + relX)
        local startY = math.floor((h - squareSize) / 2 + 1 + relZ)

        if startX >= 1 and startX <= w and startY >= 1 and startY <= h then
            mon.setCursorPos(startX, startY)
            mon.setBackgroundColor(color)
            mon.setTextColor(color) -- makes a solid color block
            mon.write(" ") -- space fills background color fully
        end
    end
    mon.setBackgroundColor(colors.black)
    mon.setTextColor(colors.white)

    for i, id in ipairs(sortedIDs) do
        local turt = turtles[id]
        local color = gradientColors[math.floor((i - 1) % #gradientColors) + 1]

        local relX = (turt.glX + turt.x - globalStartPos.x) * 0.2
        local relZ = (turt.glZ + turt.z - globalStartPos.z) * 0.2
        local startX = math.floor((w - squareSize) / 2 + 1 + relX)
        local startY = math.floor((h - squareSize) / 2 + 1 + relZ)

        mon.setBackgroundColor(color)
        for y = 0, squareSize - 1 do
            mon.setCursorPos(startX, startY + y)
            mon.write(string.rep(" ", squareSize))
        end
    end

    mon.setBackgroundColor(colors.black)
    mon.setTextColor(colors.white)
    mon.setCursorPos(2, 1)
    mon.write("-= Aub Turtle HQ (version "..VERSION..") =-")
    lineGoal = 4

    for i, id in ipairs(sortedIDs) do
        local turt = turtles[id]
        local relX = turt.x - origin.x
        local relZ = turt.z - origin.z
        local relY = turt.y

        local color = gradientColors[((i - 1) % #gradientColors) + 1]
        mon.setCursorPos(1, lineGoal)
        mon.setBackgroundColor(color)
        mon.write(id .. ":X=" .. relX .. "Y=" .. relY .. "Z=" .. relZ .. "|" .. (turt.status or ""))
        lineGoal = lineGoal + 1
    end

    mon.setBackgroundColor(colors.black)
    mon.setTextColor(colors.white)
end

-- Function: receive turtle data
local function listenForTurtles()
    while not stopSignal do
        local _, message, protocol = rednet.receive("turtlePosData", 1)  -- 1s timeout
        if message and type(message) == "table" and message.id then
            turtles[message.id] = {
                x = message.x, y = message.y, z = message.z,
                glX = message.glX, glY = message.glY, glZ = message.glZ,
                status = message.status
            }
            trails[trailIdToSet] = {
                x = (message.glX + message.x - globalStartPos.x),
                y = message.y,
                z = (message.glZ + message.z - globalStartPos.z)
            }
            trailIdToSet = trailIdToSet + 1
            if trailIdToSet > 256 then trailIdToSet = 0 end
        end
        draw()
        sleep(0.1)
    end
end

-- Function: accept terminal input
local function listenForInput()
    term.clear()
    lineGoal = 1
    term.setCursorPos(1, 1)
    term.write("Status : ONLINE")
    term.setCursorPos(1, 2)
    term.write("version "..VERSION)
    while not stopSignal do
        term.setCursorPos(1, 3)
        term.setTextColor(colors.yellow)
        term.write("Command: ")
        term.setTextColor(colors.white)
        input = read()
        term.clear()
        term.setCursorPos(1, 4)
        if (string.find(input, "return")) then
            rednet.broadcast({
                title = "turtleAubReturn"
            }, "turtleAubCommand")
            term.write("Forcing all turtles to return to origin.")
        end
        if (string.find(input, "mine deep")) then
            rednet.broadcast({
                title = "turtleAubMineDeep"
            }, "turtleAubCommand")
            term.write("Commanded all to Mine Deep.")
        end
        if (input == "go") then
            rednet.broadcast({
                title = "turtleAubGo"
            }, "turtleAubCommand")
            term.write("Commanded all turtles to start mining")
        end
        if (input == "help") then
            term.write("return : makes all turtles return.")
            term.setCursorPos(1, 5)
            term.write("mine deep : makes all turtles mine deep 90 blocks and more")
            term.setCursorPos(1, 6)
            term.write("go : makes all the turtles mine.")
        end
    end
end

-- Start both listeners in parallel
parallel.waitForAny(listenForTurtles, listenForInput)

-- Cleanup when stopped
print("ended")
mon.clear()
mon.setCursorPos(1, 1)
mon.write("Aub turtle HQ ("..VERSION..") | Status : OFFLINE")
print("Status : OFFLINE")