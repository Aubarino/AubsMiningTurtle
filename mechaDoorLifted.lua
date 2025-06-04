local steamSpeaker = peripheral.wrap("left")

if not steamSpeaker then
    print("Error: Missing speaker!")
    return
end
local inputSide = "right"

local steamWarningInterval = 0.5
local nextsteamWarningTime = os.clock()

while true do
    if redstone.getInput(inputSide) then
        local now = os.clock()

        if now >= nextsteamWarningTime then
            steamSpeaker.playSound("create:steam", 2.5, 0.55)
            nextsteamWarningTime = now + steamWarningInterval
        end
        sleep(0.025)
    else
        nextsteamWarningTime = os.clock()
        sleep(0.2)
    end
end