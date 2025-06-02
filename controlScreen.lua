-- controlScreen.lua
-- full execution: wget run https://raw.githubusercontent.com/Aubarino/AubsMiningTurtle/refs/heads/main/controlScreen.lua

-- Setup
local origin = {x = 0, z = 0}
local turtles = {}
local trails = {}
local trailIdToSet = 0
local stopSignal = false
rednet.open("back")
local input = ""
local lineGoal = 1
VERSION = "k"

local gradientColors = {
    colors.red, colors.orange, colors.yellow, colors.lime,
    colors.green, colors.cyan, colors.blue, colors.purple
}
local gradientShades = {
    colors.white, colors.lightGray, colors.gray, colors.gray
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

-- Drawing function
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
        local absY = math.abs(trail.y or 0)
        local maxY = 16
        local ratio = math.min(absY / maxY, 1)
        local depthIndex = math.floor((1 - ratio) * (#gradientShades - 1)) + 1
        local color = gradientShades[depthIndex]
        local relX = trail.x * 0.2
        local relZ = trail.z * 0.2
        local startX = math.floor((w - squareSize) / 2 + 1 + relX)
        local startY = math.floor((h - squareSize) / 2 + 1 + relZ)

        if startX >= 1 and startX <= w and startY >= 1 and startY <= h then
            mon.setCursorPos(startX, startY)
            mon.setBackgroundColor(color)
            mon.setTextColor(color)
            mon.write(" ")
        end
    end

    mon.setBackgroundColor(colors.black)
    mon.setTextColor(colors.white)
    mon.setCursorPos(1, 1)
    mon.write("Aub Turtle HQ (version "..VERSION..")")
    lineGoal = 3

    for i, id in ipairs(sortedIDs) do
        local turt = turtles[id]
        local relX = turt.x - origin.x
        local relZ = turt.z - origin.z
        local relY = turt.y
        local color = gradientColors[((i - 1) % #gradientColors) + 1]

        local relDispX = (turt.glX + turt.x - 650) * 0.2
        local relDispZ = (turt.glZ + turt.z - 379) * 0.2
        local startX = math.floor((w - squareSize) / 2 + 1 + relDispX)
        local startY = math.floor((h - squareSize) / 2 + 1 + relDispZ)

        mon.setBackgroundColor(color)
        for y = 0, squareSize - 1 do
            mon.setCursorPos(startX, startY + y)
            mon.write(string.rep(" ", squareSize))
        end

        mon.setBackgroundColor(colors.black)
        mon.setTextColor(colors.white)
        mon.setCursorPos(1, lineGoal)
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
                x = (message.glX + message.x - 650),
                y = message.y,
                z = (message.glZ + message.z - 379)
            }
            trailIdToSet = trailIdToSet + 1
            if trailIdToSet > 256 then trailIdToSet = 0 end
            draw()
        end
        sleep(0.05)
    end
end

-- Function: accept terminal input
local function listenForInput()
    while not stopSignal do
        term.setCursorPos(1, lineGoal + 2)
        term.setTextColor(colors.yellow)
        term.write("Command: ")
        term.setTextColor(colors.white)
        input = read()
        if input == "end" or input == "stop" then
            stopSignal = true
        elseif input:sub(1, 4) == "ping" then
            print("Ping acknowledged!")
        elseif input:sub(1, 4) == "say " then
            local msg = input:sub(5)
            rednet.broadcast({cmd = "say", message = msg}, "turtleCommands")
            print("Broadcast: " .. msg)
        elseif input == "broadcast stop" then
            rednet.broadcast({cmd = "stop"}, "turtleCommands")
            print("Sent stop command to all turtles.")
        else
            print("Unknown command: " .. input)
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