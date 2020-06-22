local ShootPlayer = {}
ShootPlayer.__index = ShootPlayer

function ShootPlayer.new(player, coords, game)
  local player = {
    player = player,
    x = (coords.x - 1) * game.assets.tileset.tilew,
    y = (coords.y - 1) * game.assets.tileset.tileh,
    t = 0,
    grounded = true,
    xvel = 0,
    yvel = 1,
    direction = "right",
    tileset = game.assets.tileset,
    map = game.assets.map,
    game = game,
  }

  for i, layer in pairs(game.assets.map.layers) do
    if layer.name == "fg" then
      player.fg = layer
    end
  end

  assert(not (player.fg == nil), "map is missing fg layer")

  setmetatable(player, ShootPlayer)
  return player
end

local playerTiles = {17, 19, 25, 27}

function ShootPlayer:checkCollideAt(x, y)
  x = math.floor(x / self.tileset.tilew)
  y = math.floor(y / self.tileset.tileh)
  local tileIndex = y * self.map.width + x + 1
  return not (self.fg.data[tileIndex] == 0)
end

function ShootPlayer:checkCollide(dx, dy, givex, givey)
  local x = self.x + dx
  local y = self.y + dy
  local result = {x = x, y = y, grounded = false, collide = false}

  local boundLeft = x + 12 + givex
  local boundRight = x + 21 - givex
  local boundTop = y + 10 + givey
  local boundBottom = y + 32 - givey

  local topLeft = self:checkCollideAt(boundLeft, boundTop)
  local topRight = self:checkCollideAt(boundRight, boundTop)
  local bottomLeft = self:checkCollideAt(boundLeft, boundBottom)
  local bottomRight = self:checkCollideAt(boundRight, boundBottom)

  if bottomLeft or bottomRight then
    result.grounded = true
    result.y = math.floor(result.y / 32) * 32
  elseif topLeft or topRight then
    result.y = math.ceil(result.y / 32) * 32 - 10
  end

  if topLeft or bottomLeft then
    result.x = math.ceil(result.x / 32) * 32 - 12
  elseif topRight or bottomRight then
    result.x = math.floor(result.x / 32) * 32 + (32 - 21)
  end

  result.collide = topLeft or topRight or bottomLeft or bottomRight

  return result
end

function ShootPlayer:update(dt)
  if game.input.p[self.player].r > 0 then
    self.xvel = self.xvel + 1
    if self.xvel > 4 then
      self.xvel = 4
    end
    if self.xvel > 0 then self.direction = "right" end
  elseif game.input.p[self.player].l > 0 then
    self.xvel = self.xvel - 1
    if self.xvel < -4 then
      self.xvel = -4
    end
    if self.xvel < 0 then self.direction = "left" end
  elseif self.xvel > 0 then
    self.xvel = self.xvel - 1
  elseif self.xvel < 0 then
    self.xvel = self.xvel + 1
  end
  if self.yvel < 5 then
    self.yvel = self.yvel + 0.5
  end
  if game.input.p[self.player].a > 0 and self.grounded then
    self.yvel = -12
    self.grounded = false
    self.game.assets.jump:stop()
    self.game.assets.jump:play()
  end

  local collide = self:checkCollide(self.xvel, -1, 0, 2)
  self.x = collide.x

  collide = self:checkCollide(0, self.yvel, 2, 0)
  self.y = collide.y
  self.grounded = collide.grounded
  if self.grounded then
    self.yvel = 0
  end
end

function ShootPlayer:draw(dx, dy)
  local tile = playerTiles[self.player]

  if math.floor(self.t * 2) % 2 == 1 then
    tile = tile + 1
  end

  self.tileset:drawTile(self.x + dx, self.y + dy, tile)
end

return ShootPlayer