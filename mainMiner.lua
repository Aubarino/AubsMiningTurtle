-- Position and direction tracking
local pos = { x = 0, y = 0, z = 0 }
local globalStartPos = { x = 0, y = 0, z = 0 }
local dir = 0 -- 0=north, 1=east, 2=south, 3=west
local maxDistance = 16
local downOffset = 16
local ventures = 3
local tripsToDo = 3
local tripsStandard = 3
local turtNumber = 0
local id = "AubMiner0"
local status = ""
local doItAgain = false

local forceReturn = false
local forceMineDeep = false

local oreCheckTimer = 0
print("===============================")
print("Aub turtle miner || version 2d2")
print("===============================")

print("Enter starting pos : x y z")
local input = read()

-- Split input string into x, y, z
local xStr, yStr, zStr = input:match("^(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)$")
if not xStr then
    print("Invalid input. Please enter three space-separated numbers.")
    return
end
print("Enter turtle number ID from 0")
input = read()
turtNumber = tonumber(input)
os.setComputerLabel("AubMiner"..turtNumber)
id = os.getComputerLabel() or tostring(os.getComputerID())

globalStartPos = {
    x = tonumber(xStr),
    y = tonumber(yStr),
    z = tonumber(zStr)
}

pos = {x = 0, y = 0, z = 0} -- relative position from globalStartPos

rednet.open("left") -- or whatever side the modem is on

local function sendPosition(progressStatus)
    rednet.broadcast({
        id = id,
        x = pos.x,
        y = pos.y,
        z = pos.z,
        glX = globalStartPos.x,
        glY = globalStartPos.y,
        glZ = globalStartPos.z,
        status = progressStatus
    }, "turtlePosData")
end

local function clamp(val, lower, upper)
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end

local function tryRefuel()
    if turtle.getFuelLevel() == "unlimited" or turtle.getFuelLevel() > 0 then return true end
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.refuel(1) then
            print("Refueled using slot " .. slot)
            return true
        end
    end
    print("Out of fuel!")
    return false
end

local function turnRight()
    turtle.turnRight()
    dir = (dir + 1) % 4
end

local function turnLeft()
    turtle.turnLeft()
    dir = (dir + 3) % 4
end

local function faceDirection(targetDir)
    while dir ~= targetDir do
        turnRight()
    end
end

local function rightOf(d)
    return (d + 1) % 4
end

local function leftOf(d)
    return (d + 3) % 4
end

local function dirToVector(d)
    if d == 0 then return {x=0, z=-1} -- north
    elseif d == 1 then return {x=1, z=0} -- east
    elseif d == 2 then return {x=0, z=1} -- south
    elseif d == 3 then return {x=-1, z=0} -- west
    end
end

local function isBlockUnbreakable(directionVector)
    local success, data
    if directionVector.y == 1 then
        success, data = turtle.inspectUp()
    elseif directionVector.y == -1 then
        success, data = turtle.inspectDown()
    else
        success, data = turtle.inspect()
    end
    if not success then return false end

    if data.tags then
        for _, tag in ipairs(data.tags) do
            if (tag == "minecraft:unbreakable" or tag == "unbreakable") and tag ~= "minecraft:air" then
                return true
            end
        end
    end

    if data.name then
        local nameLower = string.lower(data.name)
        if nameLower:find("chest") or nameLower:find("turtle") or nameLower:find("furnace") or nameLower:find("dropper") then
            return true
        end
    end

    return false
end

function detectNearbyOreWorld(doBack)
    local checks = {}

    local worldDirs = {
        [0] = {x=0, y=0, z=-1},  -- North
        [1] = {x=1, y=0, z=0},   -- East
        [2] = {x=0, y=0, z=1},   -- South
        [3] = {x=-1, y=0, z=0}   -- West
    }

    -- Forward
    table.insert(checks, {
        vec = worldDirs[dir],
        check = function() return turtle.inspect() end
    })

    -- Left
    table.insert(checks, {
        vec = worldDirs[(dir + 3) % 4],
        check = function()
            turtle.turnLeft()
            local ok, data = turtle.inspect()
            turtle.turnRight()
            return ok, data
        end
    })

    -- Back
    if (doBack) then
        table.insert(checks, {
            vec = worldDirs[(dir + 2) % 4],
            check = function()
                turtle.turnLeft()
                turtle.turnLeft()
                local ok, data = turtle.inspect()
                turtle.turnRight()
                turtle.turnRight()
                return ok, data
            end
        })
    end

    -- Right
    table.insert(checks, {
        vec = worldDirs[(dir + 1) % 4],
        check = function()
            turtle.turnRight()
            local ok, data = turtle.inspect()
            turtle.turnLeft()
            return ok, data
        end
    })

    -- Up
    table.insert(checks, {
        vec = {x=0, y=1, z=0},
        check = function() return turtle.inspectUp() end
    })

    -- Down
    table.insert(checks, {
        vec = {x=0, y=-1, z=0},
        check = function() return turtle.inspectDown() end
    })

    for _, check in ipairs(checks) do
        local success, data = check.check()
        if success and data.name then
            local nameLower = string.lower(data.name)
            if string.find(nameLower, "ore") or string.find(nameLower, "magnetite") then
                print("Found ore block at world direction:", check.vec.x, check.vec.y or 0, check.vec.z)
                return check.vec
            end
        end
    end

    return {x=0, y=0, z=0} -- No ore found
end

local moveOrMineVecAvoid

moveOrMineVecAvoid = function(dirVec, preferLevel)
    if not tryRefuel() then return false end

    local function tryMove(dVec)
        if isBlockUnbreakable(dVec) then
            local directions = {
                {x=1, y=0, z=0}, {x=-1, y=0, z=0},
                {x=0, y=0, z=1}, {x=0, y=0, z=-1},
                {x=0, y=1, z=0}, {x=0, y=-1, z=0}
            }
            local idx = math.random(#directions)
            local rndVec = directions[idx]
            return moveOrMineVecAvoid(rndVec)
        end

        local success = false
        if dVec.y == 1 then
            if turtle.detectUp() then turtle.digUp() end
            success = turtle.up()
            if success then pos.y = pos.y + 1 end
        elseif dVec.y == -1 then
            if turtle.detectDown() then turtle.digDown() end
            success = turtle.down()
            if success then pos.y = pos.y - 1 end
        else
            local targetDir
            if dVec.x == 1 then targetDir = 1
            elseif dVec.x == -1 then targetDir = 3
            elseif dVec.z == 1 then targetDir = 2
            elseif dVec.z == -1 then targetDir = 0
            else return false end

            faceDirection(targetDir)
            if turtle.detect() then turtle.dig() end
            success = turtle.forward()
            if success then
                if dir == 0 then pos.z = pos.z - 1
                elseif dir == 1 then pos.x = pos.x + 1
                elseif dir == 2 then pos.z = pos.z + 1
                elseif dir == 3 then pos.x = pos.x - 1 end
            end
        end
        return success
    end

    if tryMove(dirVec) then return true end

    if dirVec.y == 0 then
        local targetDir
        if dirVec.x == 1 then targetDir = 1
        elseif dirVec.x == -1 then targetDir = 3
        elseif dirVec.z == 1 then targetDir = 2
        elseif dirVec.z == -1 then targetDir = 0 end

        if targetDir then
            for _, sideDirFunc in ipairs({rightOf, leftOf}) do
                local sideDir = sideDirFunc(targetDir)
                local sideVec = dirToVector(sideDir)
                if tryMove(sideVec) and tryMove(dirVec) then
                    return true
                end
                -- Backtrack
                faceDirection((sideDir + 2) % 4)
                turtle.back()
                if dir == 0 then pos.z = pos.z + 1
                elseif dir == 1 then pos.x = pos.x - 1
                elseif dir == 2 then pos.z = pos.z - 1
                elseif dir == 3 then pos.x = pos.x + 1 end
            end
        end

        if not preferLevel then
            for _, vert in ipairs({{x=0, y=1, z=0}, {x=0, y=-1, z=0}}) do
                if tryMove(vert) and tryMove(dirVec) then return true end
                tryMove({x=0, y=-vert.y, z=0})
            end
        end
    else
        for _, sideDirFunc in ipairs({rightOf, leftOf}) do
            local sideDir = sideDirFunc(dir)
            local sideVec = dirToVector(sideDir)
            if tryMove(sideVec) and tryMove(dirVec) then return true end
            faceDirection((sideDir + 2) % 4)
            turtle.back()
            if dir == 0 then pos.z = pos.z + 1
            elseif dir == 1 then pos.x = pos.x - 1
            elseif dir == 2 then pos.z = pos.z - 1
            elseif dir == 3 then pos.x = pos.x + 1 end
        end
    end

    return false
end

function dropNonFuelItemsIntoChest()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            local isFuel = turtle.refuel(0)
            if not isFuel then
                local item = turtle.getItemDetail(slot)
                local before = item.count
                if turtle.drop() then
                    local afterDetail = turtle.getItemDetail(slot)
                    local after = afterDetail and afterDetail.count or 0
                    if after < before then
                        print("Dropped " .. (before - after) .. " of " .. item.name)
                    else
                        print("Chest could not accept: " .. item.name)
                    end
                else
                    print("Drop failed for: " .. item.name)
                end
            else
                local item = turtle.getItemDetail(slot)
                print("Kept fuel item: " .. item.name)
            end
        end
    end
    turtle.select(1)
end

function faceNorth()
    while dir ~= 0 do
        turtle.turnLeft()
        dir = (dir - 1) % 4
    end
    print("Now facing North")
end

local function mineOreAttempt()
    oreCheckTimer = oreCheckTimer + 1
    sendPosition(status)
    if oreCheckTimer >= 2 then
        --sendPosition(status)
        local outDir = detectNearbyOreWorld(false)
        if (outDir.x ~= 0 or outDir.y ~= 0 or outDir.z ~= 0) then
            moveOrMineVecAvoid(outDir)
            while true do
                outDir = detectNearbyOreWorld(true)
                if (outDir.x == 0 and outDir.y == 0 and outDir.z == 0) then break end
                moveOrMineVecAvoid(outDir)
                sendPosition("Mining Ore Vein!")
            end
        end
        oreCheckTimer = 0
    end
end

local function returnToOrigin()
    print("Returning to origin...")
    status = "Returning"

    while pos.x ~= 0 do
        mineOreAttempt()
        local step = (pos.x > 0) and -1 or 1
        if not moveOrMineVecAvoid({x=step, y=0, z=0}, true) then
            print("Blocked on X axis")
            break
        end
    end
    while pos.z ~= 0 do
        mineOreAttempt()
        local step = (pos.z > 0) and -1 or 1
        if not moveOrMineVecAvoid({x=0, y=0, z=step}, true) then
            print("Blocked on Z axis")
            break
        end
    end
    while pos.y ~= 0 do
        mineOreAttempt()
        local step = (pos.y > 0) and -1 or 1
        if not moveOrMineVecAvoid({x=0, y=step, z=0}, true) then
            print("Blocked on Y axis")
            break
        end
    end

    faceNorth()
    print("At origin")
    sendPosition("At origin")
end

local function digForwardIfNeeded()
    if turtle.detect() then
        turtle.dig()
    end
end

local function listenForCommand()
    while true do
        local _, message, protocol = rednet.receive("turtleAubCommand", 1)  -- 1s timeout
        if message and type(message) == "table" then
            if (message.title == "turtleAubReturn") then
                forceReturn = true
            end
            if (message.title == "turtleAubMineDeep") then
                forceMineDeep = true
                forceReturn = true
            end
            if (message.title == "turtleAubGo") then
                forceReturn = false
                doItAgain = true
            end
        end
        sleep(0.1)
    end
end

local function doItAgainCheck()
    while true do
        input = read()
        if (input == "yes") then
            doItAgain = true
        end
        sleep(0.5)
    end
end

local function mainMineCode()
-- Main mining loop
    if (not doItAgain) then
        print("do you want to start mining?")
        while (not doItAgain) do
            sleep(1)
        end
    end
    print("starting")
    while true do
        doItAgain = false
        tripsToDo = tripsStandard
        while (tripsToDo > 0 and not forceReturn) do
            status = "Mining"
            sendPosition(status)

            -- Descend downOffset levels
            for i = 1, downOffset do
                if not moveOrMineVecAvoid({x=0, y=-1, z=0}) then
                    print("Blocked descending")
                    break
                end
                if (forceReturn) then break end
            end

            for ventureCurrent = 1, ventures do
                local zOffsetGoal = (math.random(0, 1) == 0) and -1 or 1
                print("Mining Z direction: " .. zOffsetGoal)
                status = "Mining, z" .. zOffsetGoal .. ". Trips left: " .. tripsToDo

                for i = 1, clamp((math.random(maxDistance) + 1), 0, 999) do
                    mineOreAttempt()
                    if not moveOrMineVecAvoid({x=0, y=0, z=zOffsetGoal}) then
                        break
                    end
                    if (forceReturn) then break end
                end

                local xOffsetGoal = (math.random(0, 1) == 0) and -1 or 1
                print("Mining X direction: " .. xOffsetGoal)
                status = "Mining, x" .. xOffsetGoal .. ". Trips left: " .. tripsToDo

                for i = 1, clamp((math.random(maxDistance) + 1), 0, 999) do
                    mineOreAttempt()
                    if not moveOrMineVecAvoid({x=xOffsetGoal, y=0, z=0}) then
                        break
                    end
                    if (forceReturn) then break end
                end
                if (forceReturn) then break end
            end

            returnToOrigin()

            -- Deposit items
            dropNonFuelItemsIntoChest()

            -- Ascend back to starting Y
            while pos.y < 0 do
                if not moveOrMineVecAvoid({x=0, y=1, z=0}) then
                    print("Blocked ascending")
                    break
                end
            end

            tripsToDo = tripsToDo - 1
        end
        if (forceReturn) then
            print("Commanded to return")
            status = "Returning via command"
            returnToOrigin()
            dropNonFuelItemsIntoChest()
        end

        if (forceMineDeep) then
            forceMineDeep = false
            status = "Going to mine deep now."
            print("Mining deep now")
            maxDistance = 27
            downOffset = 70
            ventures = 2
        else
            maxDistance = 18
            downOffset = 27
            ventures = 3
            print("Mining complete!")
            while (not doItAgain) do
                print("want to go again?")
                sleep(1)
            end
        end
        forceReturn = false
    end
end

parallel.waitForAny(listenForCommand,mainMineCode,doItAgainCheck)