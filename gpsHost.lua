-- gps_host.lua
-- Sets up a GPS host computer properly

-- Check for modem
local modemSide = nil
for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
    if peripheral.getType(side) == "modem" then
        modemSide = side
        break
    end
end

if not modemSide then
    print("❌ No modem found. Attach a modem to this computer.")
    return
end

-- Open the modem
rednet.open(modemSide)
print("📡 Modem opened on side: " .. modemSide)

-- Start GPS hosting
local success = gps.host()
if success then
    print("✅ GPS Host is now running.")
    print("🛰 Waiting for location requests...")
else
    print("❌ Failed to start GPS host.")
end

-- Loop to keep the program running
while true do
    sleep(60) -- Keeps the program alive without hogging the CPU
end