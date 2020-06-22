local TileSet = require("tileset")
local Camera = require("camera")
local ShootPlayer = require("shootplayer")

local ShootGame = {}
ShootGame.__index = ShootGame

function ShootGame.new()
  local shootgame = {
    t = 0,
    screenshake = 0,
  }

  setmetatable(shootgame, ShootGame)

  return shootgame
end

function ShootGame:load()
  if self.assets == nil then
    self.assets = {}

    -- gfx
    self.assets.tileset = TileSet.new("gfx/tileset-shoot.png", 32, 32)
    
    -- sfx
    self.assets.jump = love.audio.newSource("sfx/jump.wav", "static")
    self.assets.walk = love.audio.newSource("sfx/walk.wav", "static")
    self.assets.shotsm = love.audio.newSource("sfx/shotsm.wav", "static")
    self.assets.shotlg = love.audio.newSource("sfx/shotlg.wav", "static")
    self.assets.item = love.audio.newSource("sfx/item.wav", "static")
    self.assets.hitsm = love.audio.newSource("sfx/normalhit.wav", "static")
    self.assets.hitsm:setVolume(0.5)
    self.assets.hitlg = love.audio.newSource("sfx/goodhit.wav", "static")
    self.assets.hitlg:setVolume(0.5)
    self.assets.kill = love.audio.newSource("sfx/kill.wav", "static")

    -- bgm
    self.assets.bgm = love.audio.newSource("bgm/battleground.wav", "stream")
    self.assets.bgm:setLooping(true)
    
    -- data
    self.assets.map = require("data/battleground.map")
    for i, layer in pairs(self.assets.map.layers) do
      if layer.name == "fg" then
        self.fg = layer
      end
    end
  end

  self.assets.bgm:play()
  self.assets.bgm:setVolume(1)

  local playerOrigins = self.assets.tileset:getPlayerOrigins(self.assets.map)
  self.curPlayer = 1
  self.numPlayers = game.numPlayers
  self.players = {}
  for i, player in pairs(game.shootPlayers) do
    self.players[i] = ShootPlayer.new(i, playerOrigins[i], self, i == game.selfPlayer)

    -- Set camera to first player or if we're in the match, ourselves.
    if not self.camera or i == game.selfPlayer then
      self.camPlayer = i
      self.camera = Camera.new(self.players[i].x, self.players[i].y)
    end
  end

  local itemOrigins = self.assets.tileset:getItemOrigins(self.assets.map)
  self.items = {}
  for i, item in pairs(itemOrigins) do
    self.items[i] = {
      x = (item.x - 1) * (self.assets.tileset.tilew),
      y = (item.y - 1) * (self.assets.tileset.tileh),
      item = item.item
    }
  end

  self.projectiles = {}
  self.screenshake = 0

  self.state = "fadein"
  self.statet = 0
end

function ShootGame:unload()
  if not (self.assets == nil) then
    self.assets.bgm:stop()
  end
end

function ShootGame:checkCollideAt(x, y)
  x = math.floor(x / self.assets.tileset.tilew)
  y = math.floor(y / self.assets.tileset.tileh)
  local tileIndex = y * self.assets.map.width + x + 1
  return not (self.fg.data[tileIndex] == 0)
end

local function filterTable(t, keep)
  local j, n = 1, #t;
  for i=1,n do
      if (keep(t, i, j)) then
          if (i ~= j) then
              t[j] = t[i];
              t[i] = nil;
          end
          j = j + 1;
      else
          t[i] = nil;
      end
  end
  return
end

function ShootGame:setState(state)
  self.state = state
  self.statet = 0
end

function ShootGame:updateProjectiles(dt, factor)
  factor = factor or 1
  for i, projectile in pairs(self.projectiles) do
    local nearbyPlayers = nil
    for j, player in pairs(self.players) do
      if player and not (j == projectile.player) and math.abs(player.x - projectile.x) < 64 and math.abs(player.y - projectile.y) < 32 then
        if nearbyPlayers == nil then
          nearbyPlayers = {}
        end
        table.insert(nearbyPlayers, player)
      end
    end

    if nearbyPlayers == nil then
      projectile.x = projectile.x + projectile.xvel / factor
    else
      local hit = false
      for j = 1, 4 do
        local checkx = projectile.x + (projectile.xvel / factor * j / 4)
        for k, player in pairs(nearbyPlayers) do
          if player and not hit and player:checkProjectile(checkx + self.assets.tileset.tilew / 2, projectile.y + self.assets.tileset.tileh / 2, projectile.type) then
            hit = true
            self.screenshake = self.screenshake + 8
            -- hack
            projectile.x = -100
            projectile.y = -100
          end
        end
      end
      if not hit then
        projectile.x = projectile.x + projectile.xvel / factor
      end
    end
  end

  filterTable(self.projectiles, function(t, i, j)
    local projectile = t[i]
    if self:checkCollideAt(projectile.x + self.assets.tileset.tilew / 2, projectile.y + self.assets.tileset.tileh / 2) then
      return false
    end
    if projectile.x < 0 or projectile.x > self.assets.map.width * self.assets.tileset.tilew then
      return false
    end
    return true
  end)
end

function ShootGame:updateSlowMotion(dt)
  self:updateProjectiles(dt, 10)
  for i, player in pairs(self.players) do
    if player then player:updateSlowMotion(dt) end
  end
end

function ShootGame:update(dt)
  local frameInput = {}
  if game.locality == "remote" then
    if self.state == "play" then
      -- Send our own frame input.
      local myFrameInput
      if self.players[game.selfPlayer] then
         myFrameInput = self.players[game.selfPlayer]:getFrameInput()
      end
      game.host:broadcast(json.encode({ message = "frameInput", player = game.selfPlayer, frameInput = myFrameInput }))
      frameInput[game.selfPlayer] = myFrameInput

      local haveInputFrom = 1
      if self.nextFrameInput then
        for i, input in pairs(self.nextFrameInput) do
          frameInput[i] = input
          haveInputFrom = haveInputFrom + 1
        end
        self.nextFrameInput = nil
      end

      -- Receive other player's frame input.
      while haveInputFrom < game.numPlayers do
        local event = game.host:service(1)
        while event do
          if event.type == "receive" then
            if game.selfPlayer == 1 then
              for i, peer in pairs(game.peerPlayers) do
                if not (peer == event.peer) then
                  peer:send(event.data)
                end
              end
            end
            data = json.decode(event.data)
            if data.message == "frameInput" then
              if frameInput[data.player] then
                -- We may need to buffer up to 1 frame due to frame skew.
                if self.nextFrameInput == nil then
                  self.nextFrameInput = {}
                end
                self.nextFrameInput[data.player] = data.frameInput
              else
                frameInput[data.player] = data.frameInput
                haveInputFrom = haveInputFrom + 1
              end
            end
          elseif event.type == "disconnect" then
            game.scene:next(game.menu)
          end
          event = game.host:service()
        end
      end
    end
  end

  local oldState = self.state

  self.camera:update(dt)

  if self.state == "fadein" then
    if self.statet > 1 then
      self:setState("play")
    end
  elseif self.state == "play" then
    if game.locality == "local" then
      for i, player in pairs(self.players) do
        if player then player:update(dt) end
      end
    elseif game.locality == "remote" then
      for i, player in pairs(self.players) do
        if player then player:update(dt, frameInput[i]) end
      end
    end

    for i, player in pairs(self.players) do
      if player.health == 0 or player.y > (self.assets.map.height * self.assets.tileset.tileh) - 224 then
        self.assets.kill:stop()
        self.assets.kill:play()
        self.screenshake = self.screenshake + 20
        self.players[i] = nil
      end
    end

    self:updateProjectiles(dt)

    if self.players[self.camPlayer] then
      if self.camera.x0 == self.camera.x1 and self.camera.y0 == self.camera.y1 then
        self.camera:setCoords({x = self.players[self.camPlayer].x, y = self.players[self.camPlayer].y})
      else
        self.camera.x1 = self.players[self.camPlayer].x
        self.camera.y1 = self.players[self.camPlayer].y
      end
    else
      self.camPlayer = -1
      for i, player in pairs(self.players) do
        if self.camPlayer == -1 and player then
          self.camPlayer = i
          self.camera:panToCoords({x = self.players[self.camPlayer].x, y = self.players[self.camPlayer].y}, 1)
        end
      end
    end

    local playerCount = 0
    for i, player in pairs(self.players) do
      if player then playerCount = playerCount + 1 end
    end

    if playerCount == 1 then
      self:setState("winenter")
    elseif playerCount == 0 then
      self:setState("drawenter")
    end
  elseif self.state == "winenter" then
    if self.statet > 1 then
      self:setState("win")
    end
  elseif self.state == "win" then
    self:updateSlowMotion(dt)
    if self.statet > 3 then
      self:setState("fadeout")
    end
  elseif self.state == "drawenter" then
    if self.statet > 1 then
      self:setState("draw")
    end
  elseif self.state == "draw" then
    self:updateSlowMotion(dt)
    if self.statet > 3 then
      self:setState("fadeout")
    end
  elseif self.state == "fadeout" then
    self:updateSlowMotion(dt)
    if self.statet >= 1 then
      game.scene:next(game.board)
    end
    self.assets.bgm:setVolume(1 - self.statet)
  end

  if self.state == oldState then
    self.statet = self.statet + dt
  end
end

function ShootGame:draw()
  love.graphics.setCanvas(game.canvas)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.clear(0.5, 0.5, 0.5, 1)
  love.graphics.setBlendMode("alpha")

  local mx = self.camera:getMapX()
  local my = self.camera:getMapY()

  self.assets.tileset:drawMap(self.assets.map, mx, my)
  for i, player in pairs(self.players) do
    if player then player:draw(mx, my) end
  end
  love.graphics.setColor(1, 1, 1, 1)
  for i, item in pairs(self.items) do
    self.assets.tileset:drawTile(item.x + mx, item.y + my, item.item + 32)
  end
  for i, projectile in pairs(self.projectiles) do
    self.assets.tileset:drawTile(projectile.x + mx, projectile.y + my, 35)
  end

  if self.state == "fadein" then
    local a = math.round((1 - self.statet) * 8) / 8
    love.graphics.setColor(0, 0, 0, a)
    love.graphics.rectangle("fill", 0, 0, game.canvasw, game.canvash)
  elseif self.state == "winenter" then
    love.graphics.setColor(1, 1, 1, 1 - self.statet)
    love.graphics.rectangle("fill", 0, 0, game.canvasw, game.canvash)
  elseif self.state == "drawenter" then
    love.graphics.setColor(1, 1, 1, 1 - self.statet)
    love.graphics.rectangle("fill", 0, 0, game.canvasw, game.canvash)
  elseif self.state == "fadeout" then
    local a = math.round(self.statet * 8) / 8
    love.graphics.setColor(0, 0, 0, a)
    love.graphics.rectangle("fill", 0, 0, game.canvasw, game.canvash)
  end

  love.graphics.setCanvas()
  love.graphics.setColor(1, 1, 1, 1)
  local x = 0
  local y = 0
  if self.screenshake > 0 then
    self.screenshake = self.screenshake - 1
    x = math.random() * self.screenshake - self.screenshake / 2
    y = math.random() * self.screenshake - self.screenshake / 2
  end
  love.graphics.draw(game.canvas, x, y, 0, game.canvasscale)
end

return ShootGame