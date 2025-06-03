-- startup.lua
-- Reads or writes position info to a floppy disk and starts GPS host

local diskSide = "right"
local diskPath = disk.getMountPath(diskSide)
local posFile = "position.txt"

-- Ensure modem is present and open
local modemSide = nil
for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
    if peripheral.getType(side) == "modem" then
        modemSide = side
        break
    end
end

if not modemSide then
    print("❌ No modem found. Attach a modem.")
    return
end

rednet.open(modemSide)

-- Wait until a floppy is inserted
while not disk.isPresent(diskSide) do
    print("💾 Insert floppy disk into the drive on the " .. diskSide .. " side...")
    sleep(2)
end

diskPath = disk.getMountPath(diskSide)
local posFilePath = fs.combine(diskPath, posFile)

-- Try to read existing position from floppy
local function readPosition()
    if fs.exists(posFilePath) then
        local f = fs.open(posFilePath, "r")
        local text = f.readAll()
        f.close()

        local x, y, z = text:match("(-?%d+),(-?%d+),(-?%d+)")
        if x and y and z then
            return tonumber(x), tonumber(y), tonumber(z)
        end
    end
    return nil
end

-- Write position to the floppy
local function writePosition(x, y, z)
    local f = fs.open(posFilePath, "w")
    f.write(string.format("%d,%d,%d", x, y, z))
    f.close()
end

-- Prompt user to enter position
local function promptForPosition()
    print("🧭 Please enter this computer's world position.")
    io.write("X: ")
    local x = tonumber(read())
    io.write("Y: ")
    local y = tonumber(read())
    io.write("Z: ")
    local z = tonumber(read())
    return x, y, z
end

-- Get position
local x, y, z = readPosition()
if not x then
    print("⚠️ No position found on floppy.")
    x, y, z = promptForPosition()
    writePosition(x, y, z)
    print("✅ Position saved to floppy: ", x, y, z)
else
    print(string.format("📍 Position loaded from floppy: (%d, %d, %d)", x, y, z))
end

-- Start GPS host
print("🚀 Starting GPS host at: (" .. x .. ", " .. y .. ", " .. z .. ")")
shell.run("gps", "host", tostring(x), tostring(y), tostring(z))