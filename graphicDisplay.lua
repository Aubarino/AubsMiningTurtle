local mon = peripheral.wrap("left")
if not mon then return print("Monitor on left not found") end

mon.setTextScale(0.5)
local w, h = mon.getSize()

local vertices = {
    {-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1},
    {-1,-1,1},{1,-1,1},{1,1,1},{-1,1,1},
}

local faces = {
    {1,4,3,2}, {5,6,7,8}, {1,2,6,5},
    {4,8,7,3}, {1,5,8,4}, {2,3,7,6},
}

local faceFill = {"4","e","d","b","9","5"}

local function rotateX(p,a)
    local x,y,z = table.unpack(p)
    local c,s = math.cos(a), math.sin(a)
    return {x, y*c - z*s, y*s + z*c}
end

local function rotateY(p,a)
    local x,y,z = table.unpack(p)
    local c,s = math.cos(a), math.sin(a)
    return {x*c + z*s, y, -x*s + z*c}
end

local camDist = 3
local fov = math.rad(70)
local aspect = w/h
local near = 0.1

local function project(p)
    local x,y,z = table.unpack(p)
    local zc = camDist - z
    if zc <= near then zc = near end

    local scale = 1 / math.tan(fov / 2)
    local px = (x * scale / aspect) / zc
    local py = (y * scale) / zc

    local screenX = math.floor(w / 2 + px * (w / 2))
    local screenY = math.floor(h / 2 - py * (h / 2))
    return screenX, screenY, zc
end

local function sub(a,b) return {a[1]-b[1],a[2]-b[2],a[3]-b[3]} end
local function cross(a,b)
    return {
        a[2]*b[3]-a[3]*b[2],
        a[3]*b[1]-a[1]*b[3],
        a[1]*b[2]-a[2]*b[1]
    }
end
local function dot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end

local function normalize(v)
    local len = math.sqrt(dot(v,v))
    if len == 0 then return {0,0,0} end
    return {v[1]/len, v[2]/len, v[3]/len}
end

local function faceNormal(vs)
    local u = sub(vs[2], vs[1])
    local v = sub(vs[3], vs[1])
    return cross(u,v)
end

local function faceCenter(vs)
    local cx,cy,cz=0,0,0
    for _,v in ipairs(vs) do
        cx = cx + v[1]
        cy = cy + v[2]
        cz = cz + v[3]
    end
    local n = #vs
    return {cx/n, cy/n, cz/n}
end

local function fillQuad(verts2D, verts3D, faceColor, depthBuffer)
    local minX,maxX,minY,maxY=w,1,h,1
    for _,v in ipairs(verts2D) do
        minX = math.min(minX, v[1])
        maxX = math.max(maxX, v[1])
        minY = math.min(minY, v[2])
        maxY = math.max(maxY, v[2])
    end

    for y = minY, maxY do
        local fillXs = {}
        for i = 1, #verts2D do
            local a, b = verts2D[i], verts2D[(i % #verts2D) + 1]
            if (a[2] <= y and b[2] > y) or (b[2] <= y and a[2] > y) then
                local ratio = (y - a[2]) / (b[2] - a[2])
                local x = a[1] + ratio * (b[1] - a[1])
                table.insert(fillXs, math.floor(x))
            end
        end
        table.sort(fillXs)

        for i = 1, #fillXs - 1, 2 do
            local x0, x1 = fillXs[i], fillXs[i+1]
            if x0 and x1 and y >= 1 and y <= h then
                x0 = math.max(1, math.min(w, x0))
                x1 = math.max(1, math.min(w, x1))
                for x = x0, x1 do
                    -- Weighted depth interpolation
                    local sumW, sumZ = 0, 0
                    for j = 1, 4 do
                        local vx, vy = verts2D[j][1], verts2D[j][2]
                        local dz = camDist - verts3D[j][3]
                        local dist = math.max(0.001, ((x - vx)^2 + (y - vy)^2)^0.5)
                        local wgt = 1 / dist
                        sumW = sumW + wgt
                        sumZ = sumZ + dz * wgt
                    end

                    local depth = sumZ / sumW
                    local normDepth = math.min(1, math.max(0, (depth - near) / (camDist - near)))

                    local idx = x + y * 1000
                    if not depthBuffer[idx] or normDepth > depthBuffer[idx] then
                        depthBuffer[idx] = normDepth

                        local char
                        normDepth = (normDepth * 2) - 1.2
                        if normDepth< 0.33 then
                            char = string.char(0)
                        elseif normDepth< 0.66 then
                            char = string.char(127)  -- ASCII 176
                        else
                            char = string.char(153)  -- ASCII 219
                        end

                        mon.setCursorPos(x, y)
                        mon.blit(char, "f", faceColor)
                    end
                end
            end
        end
    end
end

local angleX, angleY = 0, 0

while true do
    mon.clear()
    local depthBuffer = {}

    local rotatedVerts = {}
    for i,v in ipairs(vertices) do
        local rx = rotateX(v, angleX)
        rotatedVerts[i] = rotateY(rx, angleY)
    end

    local projectedVerts = {}
    for i,v in ipairs(rotatedVerts) do
        local px, py, pz = project(v)
        projectedVerts[i] = {px, py, pz}
    end

    local faceData = {}

    for i, face in ipairs(faces) do
        local verts3D = {}
        for j=1,4 do verts3D[j] = rotatedVerts[face[j]] end
        local center = faceCenter(verts3D)
        local normal = normalize(faceNormal(verts3D))

        local viewVec = normalize({-center[1], -center[2], camDist - center[3]})
        if dot(normal, viewVec) > 0 then
            local avgZ = 0
            for _,vtx in ipairs(verts3D) do
                avgZ = avgZ + (camDist - vtx[3])
            end
            avgZ = avgZ / 4

            table.insert(faceData, {
                index = i,
                verts3D = verts3D,
                avgZ = avgZ
            })
        end
    end

    table.sort(faceData, function(a,b) return a.avgZ < b.avgZ end)

    for _,f in ipairs(faceData) do
        local projVerts = {}
        for j=1,4 do
            projVerts[j] = projectedVerts[faces[f.index][j]]
        end
        fillQuad(projVerts, f.verts3D, faceFill[f.index], depthBuffer)
    end

    angleX = angleX + 0.04
    angleY = angleY + 0.025
    sleep(0.02)
end