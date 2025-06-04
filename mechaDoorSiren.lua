
local lockingSpeaker = peripheral.wrap("left")
local trainSpeaker = peripheral.wrap("top")

if not lockingSpeaker or not trainSpeaker then
    print("Error: Missing one or both speakers!")
    return
end
local inputSide = "right"

local train3Interval = 2
local lockingWarningInterval = 0.3
local nextTrain3Time = os.clock()
local nextLockingWarningTime = os.clock()

while true do
    if redstone.getInput(inputSide) then
        local now = os.clock()

        if now >= nextTrain3Time then
            trainSpeaker.playSound("create:train3", 1.3, 1)
            nextTrain3Time = now + train3Interval
        end

        if now >= nextLockingWarningTime then
            lockingSpeaker.playSound("superbwarfare:locking_warning", 4, 1)
            nextLockingWarningTime = now + lockingWarningInterval
        end
        sleep(0.025)
    else
        nextTrain3Time = os.clock()
        nextLockingWarningTime = os.clock()
        sleep(0.2)
    end
end