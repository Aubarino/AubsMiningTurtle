local speaker = peripheral.find("speaker")
if not speaker then
    print("No speaker found!")
    return
end

local inputSide = "right"

local train3Interval = 2.5
local lockingWarningInterval = 0.2
local nextTrain3Time = os.clock()
local nextLockingWarningTime = os.clock()

while true do
    if redstone.getInput(inputSide) then
        local now = os.clock()

        if now >= nextTrain3Time then
            speaker.playSound("create:train3", 3, 1)
            nextTrain3Time = now + train3Interval
        end

        if now >= nextLockingWarningTime then
            speaker.playSound("superbwarfare:locking_warning", 4, 0.5)
            nextLockingWarningTime = now + lockingWarningInterval
        end
    else
        nextTrain3Time = os.clock()
        nextLockingWarningTime = os.clock()
    end

    sleep(0.1)
end