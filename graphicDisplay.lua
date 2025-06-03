local mon = peripheral.wrap("left")
if not mon then
    print("Monitor on left not found")
    return
end

mon.setTextScale(0.5)
local w, h = mon.getSize()

-- Cube vertices (x,y,z)
local vertices = {
    {-1, -1, -1},
    { 1, -1, -1},
    { 1,  1, -1},
    {-1,  1, -1},
    {-1, -1,  1},
    { 1, -1,  1},
    { 1,  1,  1},
    {-1,  1,  1},
}

-- Faces with vertex indices (6 faces)
local faces = {
    {1, 2, 3, 4}, -- back (-z)
    {5, 6, 7, 8}, -- front (+z)
    {1, 5, 8, 4}, -- left (-x)
    {2, 6, 7, 3}, -- right (+x)
    {4, 3, 7, 8}, -- top (+y)
    {1, 2, 6, 5}, -- bottom (-y)
}

-- Face colors (using basic colors supported)
local faceColors = {
    colors.red,
    colors.green,
    colors.blue,
    colors.yellow,
    colors.cyan,
    colors.magenta
}

-- Rotation functions
local function rotateX(point, angle)
    local x, y, z = table.unpack(point)
    local cosA = math.cos(angle)
    local sinA = math.sin(angle)
    local y2 = y * cosA - z * sinA
    local z2 = y * sinA + z * cosA
    return {x, y2, z2}
end

local function rotateY(point, angle)
    local x, y, z = table.unpack(point)
    local cosA = math.cos(angle)
    local sinA = math.sin(angle)
    local x2 = x * cosA + z * sinA
    local z2 = -x * sinA + z * cosA
    return {x2, y, z2}
end

-- Simple orthographic projection (ignore z for position)
local function project(point)
    local x, y, z = table.unpack(point)
    -- scale and translate to monitor center
    local scale = 10
    local px = math.floor(w/2 + x * scale)
    local py = math.floor(h/2 - y * scale) -- y flipped for screen coords
    return px, py, z
end

-- Draw a line (Bresenham)
local function drawLine(x0, y0, x1, y1)
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1
    local err = dx - dy

    while true do
        if x0 >=1 and x0 <= w and y0 >= 1 and y0 <= h then
            mon.setCursorPos(x0, y0)
            mon.write("#")
        end
        if x0 == x1 and y0 == y1 then break end
        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x0 = x0 + sx
        end
        if e2 < dx then
            err = err + dx
            y0 = y0 + sy
        end
    end
end

-- Draw polygon edges from projected vertices
local function drawFace(projectedVerts, color)
    mon.setTextColor(color)
    local n = #projectedVerts
    for i=1,n do
        local x0, y0 = projectedVerts[i][1], projectedVerts[i][2]
        local x1, y1 = projectedVerts[(i % n) + 1][1], projectedVerts[(i % n) + 1][2]
        drawLine(x0, y0, x1, y1)
    end
end

-- Calculate face normal for backface culling
local function faceNormal(faceVerts)
    local function vecSub(a,b)
        return {a[1]-b[1], a[2]-b[2], a[3]-b[3]}
    end
    local function cross(a,b)
        return {
            a[2]*b[3]-a[3]*b[2],
            a[3]*b[1]-a[1]*b[3],
            a[1]*b[2]-a[2]*b[1]
        }
    end
    local function normalize(v)
        local len = math.sqrt(v[1]^2 + v[2]^2 + v[3]^2)
        return {v[1]/len, v[2]/len, v[3]/len}
    end
    local a = faceVerts[1]
    local b = faceVerts[2]
    local c = faceVerts[3]
    local ab = vecSub(b,a)
    local ac = vecSub(c,a)
    local n = cross(ab, ac)
    return normalize(n)
end

-- Dot product
local function dot(a,b)
    return a[1]*b[1] + a[2]*b[2] + a[3]*b[3]
end

-- Main loop
local angleX, angleY = 0, 0

while true do
    mon.clear()
    local rotatedVerts = {}

    -- Rotate all vertices
    for i, v in ipairs(vertices) do
        local rx = rotateX(v, angleX)
        local ry = rotateY(rx, angleY)
        rotatedVerts[i] = ry
    end

    -- Project vertices
    local projectedVerts = {}
    for i, v in ipairs(rotatedVerts) do
        projectedVerts[i] = {project(v)}
    end

    -- Draw faces sorted by average Z (Painter’s algorithm)
    local faceDepths = {}
    for i, face in ipairs(faces) do
        local avgZ = 0
        local verts = {}
        for j, vi in ipairs(face) do
            avgZ = avgZ + rotatedVerts[vi][3]
            verts[j] = rotatedVerts[vi]
        end
        avgZ = avgZ / #face
        table.insert(faceDepths, {index=i, avgZ=avgZ, verts=verts})
    end
    table.sort(faceDepths, function(a,b) return a.avgZ > b.avgZ end) -- draw farthest first

    -- Draw visible faces only (backface culling)
    for _, fd in ipairs(faceDepths) do
        local normal = faceNormal(fd.verts)
        if dot(normal, {0,0,1}) < 0 then -- facing camera
            local face = faces[fd.index]
            local projVerts = {}
            for j, vi in ipairs(face) do
                projVerts[j] = projectedVerts[vi]
            end
            drawFace(projVerts, faceColors[fd.index])
        end
    end

    angleX = angleX + 0.03
    angleY = angleY + 0.05
    sleep(0.05)
end