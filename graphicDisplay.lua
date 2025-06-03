local mon = peripheral.wrap("left")
if not mon then return print("Monitor on left not found") end

mon.setTextScale(0.5)
local w, h = mon.getSize()

local vertices = {
    {-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1},
    {-1,-1,1},{1,-1,1},{1,1,1},{-1,1,1},
}

-- Consistent CCW winding (from outside)
local faces = {
    {1,4,3,2}, -- back (-z)
    {5,6,7,8}, -- front (+z)
    {1,2,6,5}, -- bottom (-y)
    {4,8,7,3}, -- top (+y)
    {1,5,8,4}, -- left (-x)
    {2,3,7,6}, -- right (+x)
}

local faceFill = {"f","e","d","b","9","5"}

local function rotateX(p,a)
    local x,y,z=table.unpack(p)
    local c,s=math.cos(a),math.sin(a)
    return {x,y*c - z*s,y*s + z*c}
end

local function rotateY(p,a)
    local x,y,z=table.unpack(p)
    local c,s=math.cos(a),math.sin(a)
    return {x*c + z*s,y,-x*s + z*c}
end

local camDist = 4 -- distance from camera to origin (cube center)
local fov = math.rad(70) -- 70 degrees FOV
local aspect = w/h
local near = 0.1

-- Perspective projection: returns screen x,y and depth z (camera space)
local function project(p)
    -- Camera is at (0,0,camDist) looking toward origin along -z
    local x,y,z = table.unpack(p)
    local zc = camDist - z -- camera space z (distance in front of camera)
    if zc <= near then zc = near end -- clamp near plane

    -- Correct perspective projection with proper aspect ratio applied inside px calculation
    local scale = 1 / math.tan(fov / 2)
    local px = (x * scale / aspect) / zc
    local py = (y * scale) / zc

    -- Convert normalized device coords to screen coords
    local screenX = math.floor(w / 2 + px * (w / 2))
    local screenY = math.floor(h / 2 - py * (h / 2))
    return screenX, screenY, zc
end

local function sub(a,b) return {a[1]-b[1],a[2]-b[2],a[3]-b[3]} end
local function cross(a,b) return {
    a[2]*b[3]-a[3]*b[2],
    a[3]*b[1]-a[1]*b[3],
    a[1]*b[2]-a[2]*b[1]
} end
local function dot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end

local function faceNormal(vs)
    local u=sub(vs[2],vs[1])
    local v=sub(vs[3],vs[1])
    return cross(u,v)
end

local function normalize(v)
    local len = math.sqrt(dot(v,v))
    if len == 0 then return {0,0,0} end
    return {v[1]/len, v[2]/len, v[3]/len}
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

local function fillQuad(verts,colorChar)
    local minX,maxX,minY,maxY=w,1,h,1
    for _,v in ipairs(verts) do
        minX=math.min(minX,v[1])
        maxX=math.max(maxX,v[1])
        minY=math.min(minY,v[2])
        maxY=math.max(maxY,v[2])
    end

    for y=minY,maxY do
        local fillXs={}
        for i=1,#verts do
            local a,b=verts[i],verts[(i%#verts)+1]
            if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then
                local ratio=(y - a[2])/(b[2]-a[2])
                local x=a[1] + ratio*(b[1]-a[1])
                table.insert(fillXs,math.floor(x))
            end
        end
        table.sort(fillXs)
        for i=1,#fillXs-1,2 do
            local x0,x1=fillXs[i],fillXs[i+1]
            if x0 and x1 and y>=1 and y<=h then
                x0=math.max(1,math.min(w,x0))
                x1=math.max(1,math.min(w,x1))
                if x0<=x1 then
                    local len=x1 - x0 + 1
                    mon.setCursorPos(x0,y)
                    mon.blit(string.rep(" ",len),string.rep(colorChar,len),string.rep(colorChar,len))
                end
            end
        end
    end
end

local angleX, angleY = 0, 0

while true do
    mon.clear()
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
        local normal = faceNormal(verts3D)
        normal = normalize(normal)

        -- View vector from face center to camera (0,0,camDist)
        local viewVec = {0 - center[1], 0 - center[2], camDist - center[3]}
        viewVec = normalize(viewVec)

        local visible = dot(normal, viewVec) > 0.001 -- visible if facing camera

        if visible then
            -- Average depth for sorting (use camera space z)
            local avgZ = 0
            for _,vtx in ipairs(verts3D) do
                avgZ = avgZ + (camDist - vtx[3])
            end
            avgZ = avgZ / 4

            table.insert(faceData, {index=i, verts3D=verts3D, avgZ=avgZ})
        end
    end

    -- Painter's algorithm: farthest faces drawn first
    table.sort(faceData, function(a,b) return a.avgZ < b.avgZ end)

    for _,f in ipairs(faceData) do
        local projVerts = {}
        for j=1,4 do
            projVerts[j] = projectedVerts[faces[f.index][j]]
        end
        fillQuad(projVerts, faceFill[f.index])
    end

    angleX = angleX + 0.04
    angleY = angleY + 0.025
    sleep(0.05)
end