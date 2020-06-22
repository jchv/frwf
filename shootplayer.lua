local ShootPlayer = {}
ShootPlayer.__index = ShootPlayer

function ShootPlayer.new(player, coords, game, human)
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
    human = human,
    fg = game.fg,
    health = 5,
    maxHealth = 5,
  }

  assert(not (player.fg == nil), "map is missing fg layer")

  setmetatable(player, ShootPlayer)
  return player
end

local playerTiles = {17, 19, 25, 27}

function ShootPlayer:checkCollide(dx, dy, givex, givey)
  local x = self.x + dx
  local y = self.y + dy
  local result = {x = x, y = y, grounded = false, collide = false}

  local boundLeft = x + 12 + givex
  local boundRight = x + 21 - givex
  local boundTop = y + 10 + givey
  local boundBottom = y + 32 - givey

  local topLeft = self.game:checkCollideAt(boundLeft, boundTop)
  local topRight = self.game:checkCollideAt(boundRight, boundTop)
  local bottomLeft = self.game:checkCollideAt(boundLeft, boundBottom)
  local bottomRight = self.game:checkCollideAt(boundRight, boundBottom)

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

  if topLeft then
    result.wall = "left"
  elseif topRight then
    result.wall = "right"
  end

  return result
end

function ShootPlayer:checkProjectile(x, y, type)
  local boundLeft = self.x + 12
  local boundRight = self.x + 21
  local boundTop = self.y + 10
  local boundBottom = self.y + 32

  if x >= boundLeft and x < boundRight and y >= boundTop and y < boundBottom then
    self.health = self.health - type
    if self.health < 0 then
      self.health = 0
    end
    if type == 1 then
      self.game.assets.hitsm:stop()
      self.game.assets.hitsm:play()
    elseif type == 2 then
      self.game.assets.hitlg:stop()
      self.game.assets.hitlg:play()
    end
    return true
  end

  return false
end

function ShootPlayer:checkCollectItems()
  for i, item in pairs(self.game.items) do
    if not (self.item) or not (self.item.item == item.item) then
      if math.abs(item.x - self.x) < 16 and math.abs(item.y - self.y) < 16 then
        table.remove(self.game.items, i)
        if self.item then
          if self.direction == "left" then
            table.insert(self.game.items, {x = self.x + 24, y = item.y, item = self.item.item})
          else
            table.insert(self.game.items, {x = self.x - 24, y = item.y, item = self.item.item})
          end
        end
        self.game.assets.item:stop()
        self.game.assets.item:play()
        self.item = item
      end
    end
  end
end

function ShootPlayer:shoot()
  local projectile = {
    x = self.x,
    y = self.y + 4,
    player = self.player,
  }

  if self.direction == "left" then
    projectile.xvel = -1
  else
    projectile.xvel = 1
  end

  if self.item.item == 1 then
    projectile.type = 1
    projectile.xvel = projectile.xvel * 16
    self.game.assets.shotsm:stop()
    self.game.assets.shotsm:play()
  elseif self.item.item == 2 then
    projectile.type = 2
    projectile.xvel = projectile.xvel * 24
    self.game.assets.shotlg:stop()
    self.game.assets.shotlg:play()
  end

  table.insert(self.game.projectiles, projectile)
end

function ShootPlayer:updateSlowMotion(dt)
  if self.yvel < 5 then
    self.yvel = self.yvel + 0.5
  end

  local collide = self:checkCollide(self.xvel / 10, -1, 0, 2)
  self.t = self.t + math.abs(self.x - collide.x) / 100
  self.x = collide.x
  self.wall = collide.wall

  collide = self:checkCollide(0, self.yvel / 10, 2, 0)
  self.y = collide.y
  self.grounded = collide.grounded
  if self.grounded then
    self.yvel = 0
  else
    self.t = 1
  end
end

function ShootPlayer:nearestGunDirection()
  local minDistance = -1
  local resultDirection = nil

  for i, item in pairs(self.game.items) do
    local distance = math.sqrt(math.pow(item.x - self.x, 2) + math.pow(item.y - self.y, 2))
    local direction = nil
    if item.x < self.x then
      direction = "left"
    else
      direction = "right"
    end

    if minDistance == -1 or distance < minDistance then
      minDistance = distance
      resultDirection = direction
    end
  end

  return resultDirection
end

function ShootPlayer:nearestPlayer()
  local minDistance = -1
  local result = nil

  for i, player in pairs(self.game.players) do
    if player and not (player.player == self.player) then
      local distance = math.sqrt(math.pow(player.x - self.x, 2) + math.pow(player.y - self.y, 2))
      if minDistance == -1 or distance < minDistance then
        minDistance = distance
        result = player
      end
    end
  end

  return result
end

function ShootPlayer:getFrameInput()
  local input = {}
  input.right = game.input.p[1].r > 0
  input.left = game.input.p[1].l > 0
  input.jump = game.input.p[1].a > 0
  input.jumpNow = input.jump and game.input.p[1].a < 3
  input.shoot = game.input.p[1].b == 1
  return input
end

function ShootPlayer:update(dt, input)
  self:checkCollectItems()
  local input = input or {}
  if self.human and game.locality == "local" then
    input = self:getFrameInput()
  else
    if game.locality == "local" then
      if not self.ai then
        self.ai = {}
        self.ai.dir = self:nearestGunDirection()
        if not self.ai.dir then
          print("unexpectedly, no nearby guns were found for player " .. self.player)
          self.ai.dir = "left"
        end
      end

      local shouldJump = false
      local shouldShoot = false

      if self.item then
        local nearestPlayer = self:nearestPlayer()
      
        if nearestPlayer then
          if self.y < nearestPlayer.y + 128 then
            if love.math.random(1, 10) == 1 then
              shouldJump = true
            end
          end

          if math.abs(nearestPlayer.x - self.x) < 256 and math.abs(nearestPlayer.y - self.y) < 64 then
            if love.math.random(1, 20) == 1 then
              if self.x < nearestPlayer.x and self.direction == "left" then
                self.ai.dir = "right"
              elseif self.x > nearestPlayer.x and self.direction == "right" then
                self.ai.dir = "left"
              end
              shouldShoot = true
            end
          end
        else
          if love.math.random(1, 25) == 1 then
            shouldJump = true
          end
        end
      else
        if love.math.random(1, 25) == 1 then
          shouldJump = true
        end
      end

      -- TODO: remove hardcoded logic :(
      if self.x < 20 * 32 then
        self.ai.dir = "right"
      elseif self.x > 78 * 32 then
        self.ai.dir = "left"
      end

      input.right = self.ai.dir == "right"
      input.left = self.ai.dir == "left"
      input.jump = shouldJump or self.grounded and self.wall == self.ai.dir
      input.jumpNow = false
      input.shoot = shouldShoot
    elseif game.locality == "remote" then
    end
  end

  if input.right then
    self.xvel = self.xvel + 1
    if self.xvel > 4 then
      self.xvel = 4
    end
    self.direction = "right"
  elseif input.left then
    self.xvel = self.xvel - 1
    if self.xvel < -4 then
      self.xvel = -4
    end
    self.direction = "left"
  elseif self.xvel > 0 then
    self.xvel = self.xvel - 1
  elseif self.xvel < 0 then
    self.xvel = self.xvel + 1
  end
  if self.yvel < 5 then
    self.yvel = self.yvel + 0.5
  end
  if input.jump and self.grounded then
    self.yvel = -12
    self.grounded = false
    self.game.assets.jump:stop()
    self.game.assets.jump:play()
  elseif input.jumpNow and not (self.wall == nil) and self.yvel > -6 then
    self.yvel = -12
    if self.wall == "left" then
      self.xvel = 6
    elseif self.wall == "right" then
      self.xvel = -6
    end
    self.wall = nil
    self.game.assets.jump:stop()
    self.game.assets.jump:play()      
  end

  if self.item and input.shoot then
    self:shoot()
  end

  if self.xvel == 0 then
    self.t = 0
  end

  local collide = self:checkCollide(self.xvel, -1, 0, 2)
  self.t = self.t + math.abs(self.x - collide.x) / 100
  self.x = collide.x
  self.wall = collide.wall

  collide = self:checkCollide(0, self.yvel, 2, 0)
  self.y = collide.y
  self.grounded = collide.grounded
  if self.grounded then
    self.yvel = 0
  else
    self.t = 1
  end
end

function ShootPlayer:draw(dx, dy)
  love.graphics.setColor(1, 1, 1, 1)
  local tile = playerTiles[self.player]

  if math.floor(self.t * 2) % 2 == 1 then
    tile = tile + 1
  end

  self.tileset:drawTile(self.x + dx, self.y + dy, tile)

  if self.item then
    if self.direction == "left" then
      self.tileset:drawTile(self.x + dx + 32, self.y + dy, self.item.item + 32, -1, 1)
    else
      self.tileset:drawTile(self.x + dx, self.y + dy, self.item.item + 32, 1, 1)
    end
  end

  love.graphics.setColor(0, 0, 0, 0.3)
  love.graphics.rectangle("fill", self.x + dx, self.y + dy - 10, 32, 1)
  love.graphics.rectangle("fill", self.x + dx, self.y + dy - 5, 32, 1)
  love.graphics.rectangle("fill", self.x + dx, self.y + dy - 9, 1, 4)
  love.graphics.rectangle("fill", self.x + dx + 31, self.y + dy - 9, 1, 4)
  love.graphics.setColor(0, 1, 0, 0.3)
  love.graphics.rectangle("fill", self.x + dx + 1, self.y + dy - 9, self.health * 30 / self.maxHealth, 4)
end

return ShootPlayer
