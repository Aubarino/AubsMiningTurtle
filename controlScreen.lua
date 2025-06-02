-- baseDisplay.lua

-- Setup
local origin = {x = 0, z = 0} -- your base reference point
local turtles = {}
local stopSignal = false
rednet.open("back") -- or side of the modem
local input = ""

-- Optional monitor support
local mon = peripheral.find("monitor")
if mon then mon.setTextScale(0.5) end
print("Status : ONLINE")
print("Peripherals : "..peripheral.getNames().tostring())
if not mon then
    print("Monitor not found!")
    return
end
print(peripheral.getType("right"))

local function draw()
    local display = mon or term
    display.clear()
    display.setCursorPos(1, 1)
    display.write("Aub turtle HQ\nStatus : ONLINE\n")

    for id, pos in pairs(turtles) do
        local relX = pos.x - origin.x
        local relZ = pos.z - origin.z
        display.write(id .. ": X=" .. relX .. " Z=" .. relZ .. "\n")
    end
end

-- Listen for position updates
while not stopSignal do
    local _, message, protocol = rednet.receive("turtlePos")
    if type(message) == "table" and message.id then
        turtles[message.id] = {x = message.x, z = message.z}
        draw()
    end
    input = read()
    if (input == "end") then
        stopSignal = true
    end
end

print("ended")
local display = mon or term
display.clear()
display.setCursorPos(1, 1)
display.write("Aub turtle HQ\nStatus : OFFLINE")
print("Status : OFFLINE")
draw()