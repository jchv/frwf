local Camera = {}
Camera.__index = Camera

function Camera.new()
  local x = 80
  local y = 72
  local camera = {x0=x, y0=y, x1=x, y1=y, t=0, duration=0}
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
    return inOutSine(self.t, self.x0, self.x1 - self.x0, self.duration)
  else
    return self.x1
  end
end

function Camera:getMapX()
  return 80 - self:getX()
end

function Camera:getY()
  if self:isPanning() then
    return inOutSine(self.t, self.y0, self.y1 - self.y0, self.duration)
  else
    return self.y1
  end
end

function Camera:getMapY()
  return 72 - self:getY()
end

function Camera:panToCoords(coords, duration)
  self.x0 = self:getX()
  self.y0 = self:getY()
  self.x1 = coords.x
  self.y1 = coords.y
  self.t = 0
  self.duration = duration or 3
end

function Camera:setCoords(coords)
  self.x0 = coords.x
  self.x1 = coords.x
  self.y0 = coords.y
  self.y1 = coords.y
  self.t = 0
  self.duration = 0
end

return Camera
