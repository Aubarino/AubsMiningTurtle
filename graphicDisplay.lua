-- spinningCube.lua
local mon = peripheral.wrap(left)
if not mon then
    print(No monitor found on the left.)
    return
end

mon.setTextScale(0.5)
local w, h = mon.getSize()

local cubeFrames = {
    {
        lines = {
               ▄▄▄   ,
              █   █  ,
             █     █ ,
             █     █ ,
              █▄▄▄█  ,
        },
        colors = {colors.red, colors.green, colors.blue}
    },
    {
        lines = {
               ▄▄    ,
              █  █▄  ,
             █    █ ,
             █   ▄█ ,
              ███   ,
        },
        colors = {colors.orange, colors.green, colors.purple}
    },
    {
        lines = {
               ▄▄▄   ,
              █   █  ,
             █     █ ,
             █     █ ,
              █▄▄▄█  ,
        },
        colors = {colors.blue, colors.lime, colors.yellow}
    },
    {
        lines = {
               ▄▄    ,
             ▄█  █   ,
             █    █ ,
             ▀█   █ ,
               ███  ,
        },
        colors = {colors.cyan, colors.red, colors.magenta}
    },
    {
        lines = {
               ▄▄▄   ,
              █   █  ,
             █     █ ,
             █     █ ,
              █▄▄▄█  ,
        },
        colors = {colors.yellow, colors.cyan, colors.green}
    },
    {
        lines = {
                ▄▄   ,
              ▄█  █  ,
             █    █ ,
             █   ▀█ ,
              ███   ,
        },
        colors = {colors.purple, colors.orange, colors.lime}
    },
    {
        lines = {
               ▄▄▄   ,
              █   █  ,
             █     █ ,
             █     █ ,
              █▄▄▄█  ,
        },
        colors = {colors.green, colors.blue, colors.red}
    },
    {
        lines = {
               ▄▄    ,
              █  █▄  ,
             █    █ ,
             █   ▄█ ,
              ███   ,
        },
        colors = {colors.magenta, colors.lime, colors.yellow}
    }
}

-- Helper to clear and draw frame centered
local function drawFrame(frame)
    mon.clear()
    local cube = cubeFrames[frame]
    local lines = cube.lines
    local colorset = cube.colors

    local startY = math.floor((h - #lines)  2) + 1
    for i, line in ipairs(lines) do
        local y = startY + i - 1
        local x = math.floor((w - #line)  2) + 1
        mon.setCursorPos(x, y)
        mon.setTextColor(colorset[(i - 1) % #colorset + 1])
        mon.write(line)
    end
end

-- Main loop
local frame = 1
while true do
    drawFrame(frame)
    frame = frame + 1
    if frame  #cubeFrames then frame = 1 end
    sleep(0.2)
end