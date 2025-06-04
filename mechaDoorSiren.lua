local speaker = peripheral.find("speaker")
if not speaker then
    print("No speaker found!")
    return
end

local side = "right" -- the side redstone input comes from
local playing = false

-- Siren pattern function
local function playSiren()
    while redstone.getInput(side) do
        -- First beep
        speaker.playSound("create:train3", 3, 1)
        sleep(2)
    end
end

-- Main loop
while true do
    if redstone.getInput(side) and not playing then
        playing = true
        print("Alarm triggered!")
        playSiren()
        playing = false
        print("Alarm off.")
    end
    sleep(0.25)
end