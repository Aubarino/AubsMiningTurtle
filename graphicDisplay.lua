local mon = peripheral.wrap("left")
if not mon then
    print("No monitor found on the left.")
    return
end

mon.setTextScale(0.5)
local w, h = mon.getSize()

-- 8 different cube perspectives
local cubeFrames = {
    {
        lines = {
            "   ▄▄▄   ",
            "  █   █  ",
            " █     █ ",
            " █     █ ",
            "  █▄▄▄█  ",
        },
        colors = {colors.red, colors.green, colors.blue}
    },
    {
        lines = {
            "   ▄▄    ",
            "  █  █▄  ",
            " █    █ ",
            " █   ▄█ ",
            "  ███   ",
        },
        colors = {colors.orange, colors.green, colors.purple}
    },
    {
        lines = {
            "   ▄▄▄   ",
            "  █   █  ",
            " █     █ ",
            " █     █ ",
            "  █▄▄▄█  ",
        },
        colors = {colors.blue, colors.lime, colors.yellow}
    },
    {
        lines = {
            "   ▄▄    ",
            " ▄█  █   ",
            " █    █ ",
            " ▀█   █ ",
            "   ███  ",
        },
        colors = {colors.cyan, colors.red, colors.magenta}
    },
    {
        lines = {
            "   ▄▄▄   ",
            "  █   █  ",
            " █     █ ",
            " █     █ ",
            "  █▄▄▄█  ",
        },
        colors = {colors.yellow, colors.cyan, colors.green}
    },
    {
        lines = {
            "    ▄▄   ",
            "  ▄█  █  ",
            " █    █ ",
            " █   ▀█ ",
            "  ███   ",
        },
        colors = {colors.purple, colors.orange, colors.lime}
    },
    {
        lines = {
            "   ▄▄▄   ",
            "  █   █  ",
            " █     █ ",
            " █     █ ",
            "  █▄▄▄█  ",
        },
        colors = {colors.green, colors.blue, colors.red}
    },
    {
        lines = {
            "   ▄▄    ",
            "  █  █▄  ",
            " █    █ ",
            " █   ▄█ ",
            "  ███   ",
        },
        colors = {colors.magenta, colors.lime, colors.yellow}
    }
}

-- Helper to draw a centered frame
local function drawFrame(frameIndex)
    mon.clear()
    local frame = cubeFrames[frameIndex]
    local lines = frame.lines
    local colorset = frame.colors

    local startY = math.floor((h - #lines) / 2) + 1
    for i, line in ipairs(lines) do
        local y = startY + i - 1
        local x = math.floor((w - #line) / 2) + 1
        mon.setCursorPos(x, y)
        mon.setTextColor(colorset[(i - 1) % #colorset + 1])
        mon.write(line)
    end
end

-- Loop through cube frames to animate
local frame = 1
while true do
    drawFrame(frame)
    frame = (frame % #cubeFrames) + 1
    sleep(0.2)
end