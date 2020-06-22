local BoardPlayer = {}
BoardPlayer.__index = BoardPlayer

function BoardPlayer.new(player, coords, human)
  local player = {player = player, x = coords.x, y = coords.y, x1 = coords.x, y1 = coords.y, t = 0, duration = 0, state = "idle", direction = nil, human = human}
  setmetatable(player, BoardPlayer)
  return player
end

function BoardPlayer:getStatus(graph)
  local node = graph:getNodeAt(self)
  
  if not (self.state == "idle") then
    return "busy"
  end

  if node:isOrphan() then
    return "hop"
  end

  if node:isOneWay() then
    return "move"
  end

  if node:isTwoWay() and not (self.direction == nil) then
    return "move"
  end

  return "pick"
end

function BoardPlayer:getPickChoices(graph)
  local node = graph:getNodeAt(self)
  local choices = {}
  if not (node.right == nil) and not (self.direction == "left")  then choices.right = true end
  if not (node.down == nil) and not (self.direction == "up") then choices.down = true end
  if not (node.left == nil) and not (self.direction == "right") then choices.left = true end
  if not (node.up == nil) and not (self.direction == "down") then choices.up = true end
  return choices
end

function BoardPlayer:forceIdle()
  self.x = self.x1
  self.y = self.y1
  self.t = 0
  self.duration = 0
  self.state = "idle"
end

function BoardPlayer:hopNearby(graph, duration)
  assert(self.state == "idle", "trying to hop while not idle")

  local node = graph:getNodeAt(self)
  local jumpTo = graph:getJumpNode(node)

  self.x1 = jumpTo.x
  self.y1 = jumpTo.y
  self.t = 0
  self.duration = duration or 1
  self.state = "hopping"
end

function BoardPlayer:moveWithChoice(graph, choice, duration)
  assert(self.state == "idle", "trying to move while not idle")

  self.x1 = self.x
  self.y1 = self.y

  if choice == "right" then self.x1 = self.x + 1
  elseif choice == "down" then self.y1 = self.y + 1
  elseif choice == "left" then self.x1 = self.x - 1
  elseif choice == "up" then self.y1 = self.y - 1
  end

  self.t = 0
  self.direction = choice
  self.duration = duration or 0.5
  self.state = "moving"
end

function BoardPlayer:move(graph, duration)
  assert(self.state == "idle", "trying to move while not idle")

  local node = graph:getNodeAt(self)
  local moveTo = nil

  -- Moving straight
  if self.direction == "right" and not (node.right == nil) then moveTo = node.right
  elseif self.direction == "down" and not (node.down == nil) then moveTo = node.down
  elseif self.direction == "left" and not (node.left == nil) then moveTo = node.left
  elseif self.direction == "up" and not (node.up == nil) then moveTo = node.up
  -- Corner moves
  elseif not (self.direction == "left") and not (node.right == nil) then moveTo = node.right; self.direction = "right"
  elseif not (self.direction == "up") and not (node.down == nil) then moveTo = node.down; self.direction = "down"
  elseif not (self.direction == "right") and not (node.left == nil) then moveTo = node.left; self.direction = "left"
  elseif not (self.direction == "down") and not (node.up == nil) then moveTo = node.up; self.direction = "up"
  -- Dead ends (turn around)
  elseif not (node.right == nil) then moveTo = node.right; self.direction = "right"
  elseif not (node.down == nil) then moveTo = node.down; self.direction = "down"
  elseif not (node.left == nil) then moveTo = node.left; self.direction = "left"
  elseif not (node.up == nil) then moveTo = node.up; self.direction = "up" end

  assert(not (moveTo == nil), "invalid move")

  self.x1 = moveTo.x
  self.y1 = moveTo.y
  self.t = 0
  self.duration = duration or 0.5
  self.state = "moving"
end

function BoardPlayer:update(dt)
  self.t = self.t + dt

  if self.t > self.duration then
    self.state = "idle"
    self.duration = 0
    self.t = 0
    self.x = self.x1
    self.y = self.y1
  end
end

local function linear(t, b, c, d) return c * t / d + b end

function BoardPlayer:getMapCoords(tileset)
  local c1 = {x = (self.x - 1) * tileset.tilew, y = (self.y - 1) * tileset.tileh}
  local c2 = {x = (self.x1 - 1) * tileset.tilew, y = (self.y1 - 1) * tileset.tileh}

  if self.state == "hopping" then
    local result = {
      x = linear(self.t, c1.x, c2.x - c1.x, self.duration),
      y = linear(self.t, c1.y, c2.y - c1.y, self.duration),
    }
    -- Do a little hop on the y coordinate.
    result.y = result.y - math.sin(self.t * math.pi / self.duration) * 20
    return result
  elseif self.state == "moving" then
    return {
      x = linear(self.t, c1.x, c2.x - c1.x, self.duration),
      y = linear(self.t, c1.y, c2.y - c1.y, self.duration),
    }
  else
    return c1
  end
end

local playerTiles = {17, 19, 25, 27}

function BoardPlayer:draw(tileset, dx, dy)
  local coords = self:getMapCoords(tileset)
  local tile = playerTiles[self.player]

  if math.floor(self.t * 2) % 2 == 1 then
    tile = tile + 1
  end

  tileset:drawTile(coords.x + dx, coords.y + dy - 16, tile)
end

return BoardPlayer
