-- 3D Cube Renderer on Advanced Monitor

local mon = peripheral.wrap("left")
mon.setTextScale(0.5)
local w, h = mon.getSize()
local centerX, centerY = math.floor(w/2), math.floor(h/2)

local cubeSize = 6
local cube = {
    {-1, -1, -1}, {1, -1, -1}, {1, 1, -1}, {-1, 1, -1},
    {-1, -1, 1},  {1, -1, 1},  {1, 1, 1},  {-1, 1, 1}
}

local faces = {
    {1, 2, 3, 4, "A"}, -- back
    {5, 6, 7, 8, "B"}, -- front
    {1, 5, 8, 4, "C"}, -- left
    {2, 6, 7, 3, "D"}, -- right
    {4, 3, 7, 8, "E"}, -- top
    {1, 2, 6, 5, "F"}  -- bottom
}

local function rotate(v, ax, ay)
    local x, y, z = v[1], v[2], v[3]
    local cosx, sinx = math.cos(ax), math.sin(ax)
    local cosy, siny = math.cos(ay), math.sin(ay)

    y, z = y * cosx - z * sinx, y * sinx + z * cosx
    x, z = x * cosy + z * siny, -x * siny + z * cosy
    return {x, y, z}
end

local function project(v)
    local scale = 8 / (v[3] + 6)
    return {
        x = math.floor(centerX + v[1] * scale * cubeSize),
        y = math.floor(centerY - v[2] * scale * cubeSize),
        z = v[3]
    }
end

local function drawCube(angleX, angleY)
    mon.clear()
    local points3D = {}
    for i = 1, #cube do
        points3D[i] = rotate(cube[i], angleX, angleY)
    end

    local projected = {}
    for i = 1, #points3D do
        projected[i] = project(points3D[i])
    end

    local visibleFaces = {}
    for _, face in ipairs(faces) do
        local p1, p2, p3 = points3D[face[1]], points3D[face[2]], points3D[face[3]]
        local ux, uy, uz = p2[1]-p1[1], p2[2]-p1[2], p2[3]-p1[3]
        local vx, vy, vz = p3[1]-p1[1], p3[2]-p1[2], p3[3]-p1[3]
        local nx, ny, nz = uy*vz - uz*vy, uz*vx - ux*vz, ux*vy - uy*vx

        if nz < 0 then
            local avgZ = (points3D[face[1]][3] + points3D[face[2]][3] + points3D[face[3]][3] + points3D[face[4]][3]) / 4
            table.insert(visibleFaces, {face, avgZ})
        end
    end

    table.sort(visibleFaces, function(a, b) return a[2] < b[2] end)

    for _, item in ipairs(visibleFaces) do
        local face = item[1]
        local sym = face[5]
        local pts = {}
        for i = 1, 4 do
            table.insert(pts, projected[face[i]])
        end

        local minX, maxX = math.huge, -math.huge
        local minY, maxY = math.huge, -math.huge
        for _, p in ipairs(pts) do
            if p.x < minX then minX = p.x end
            if p.x > maxX then maxX = p.x end
            if p.y < minY then minY = p.y end
            if p.y > maxY then maxY = p.y end
        end

        for y = minY, maxY do
            if y >= 1 and y <= h then
                for x = minX, maxX do
                    if x >= 1 and x <= w then
                        mon.setCursorPos(x, y)
                        mon.write(sym)
                    end
                end
            end
        end
    end
end

local angleX, angleY = 0, 0
while true do
    drawCube(angleX, angleY)
    angleX = angleX + 0.05
    angleY = angleY + 0.03
    sleep(0.1)
end