map = {}

function map.loadtiles(tileset, tilew, tileh)
    local set = {}
    set.tilew = tilew
    set.tileh = tileh
    set.img = love.graphics.newImage(tileset)
    set.quads = {}

    local imgw = set.img:getWidth()
    local imgh = set.img:getHeight()
    local tilel = imgw / tilew
    local tilev = imgh / tileh
    local i = 1

    for ty = 0, tilev - 1 do
        for tx = 0, tilel - 1 do
            set.quads[i] = love.graphics.newQuad(tx * tilew, ty * tileh, tilew, tileh, imgw, imgh)
            i = i + 1
        end
    end

    return set
end

function map.drawtile(tileset, x, y, tile)
  love.graphics.draw(tileset.img, tileset.quads[tile], x, y)
end

function map.drawtilelayer(layer, tileset, dx, dy)
    for y = 0, layer.height - 1 do
        for x = 0, layer.width - 1 do
            local tile = layer.data[y * layer.width + x + 1]
            if tile > 0 then
                map.drawtile(tileset, x * tileset.tilew + dx, y * tileset.tileh + dy, tile)
            end
        end
    end
end

function map.drawmap(tilemap, tileset, dx, dy)
    for i, layer in pairs(tilemap.layers) do
        if layer.type == "tilelayer" then
            map.drawtilelayer(layer, tileset, dx, dy)
        end
    end
end

local Camera = {}
Camera.__index = Camera

function map.newCamera(x, y)
    local camera = {x0=x, y0=y, x1=x, y1=y, t=0, duration=1}
    setmetatable(camera, Camera)
    return camera
end

function Camera:isPanning()
    return not (self.x0 == self.x1 and self.y0 == self.y1)
end

function Camera:update(dt)
    if not self:isPanning() then
        return
    end

    self.t = self.t + dt
    if self.t > self.duration then
        self.x0 = self.x1
        self.y0 = self.y1
        self.t = 0
    end
end

local function inOutSine(t, b, c, d)
    return -c / 2 * (math.cos(math.pi * t / d) - 1) + b
end

function Camera:getX()
    if self:isPanning() then
        return inOutSine(self.t, self.x0, self.x1, self.duration)
    else
        return self.x1
    end
end

function Camera:getMapX()
    return 80 - self:getX()
end

function Camera:getY()
    if self:isPanning() then
        return inOutSine(self.t, self.y0, self.y1, self.duration)
    else
        return self.y1
    end
end

function Camera:getMapY()
    return 72 - self:getY()
end

function Camera:panToCoords(x, y)
    self.x0 = self:getX()
    self.y0 = self:getY()
    self.x1 = x
    self.y1 = y
    self.t = 0
end

return map
