local BoardGame = {}
BoardGame.__index = BoardGame

local Camera = require("camera")
local MapGraph = require("mapgraph")
local BoardPlayer = require("boardplayer")
local TileSet = require("tileset")

local badhitLen = 12
local goodhitLen = 6

function BoardGame.new()
  local boardgame = {
    t = 0,
  }

  setmetatable(boardgame, BoardGame)

  return boardgame
end

function BoardGame:load()
  if self.assets == nil then
    self.assets = {}

    -- gfx
    self.assets.tileset = TileSet.new("gfx/tileset.png", 32, 32)
    self.assets.cursorimg = love.graphics.newImage("gfx/cursor.png")
    
    -- sfx
    self.assets.normalhit = love.audio.newSource("sfx/normalhit.wav", "static")
    self.assets.goodhit = love.audio.newSource("sfx/goodhit.wav", "static")
    self.assets.badhit = love.audio.newSource("sfx/badhit.wav", "static")
    self.assets.jump = love.audio.newSource("sfx/jump.wav", "static")
    self.assets.walk = love.audio.newSource("sfx/walk.wav", "static")
    self.assets.walk:setLooping(true)
    
    -- bgm
    self.assets.bgm = love.audio.newSource("bgm/nihilists.wav", "stream")
    self.assets.bgm:setLooping(true)
    
    -- data
    self.assets.map = require("data/boredisle.map")
    self.graph = MapGraph.new(self.assets.map)
  end

  self.assets.bgm:play()
  self.assets.bgm:setVolume(1)

  if self.camera == nil then
    self.camera = Camera.new(game.canvasw / 2, game.canvash / 2)
  end

  if self.players == nil then
    local playerOrigins = self.assets.tileset:getPlayerOrigins(self.assets.map)
    self.numPlayers = game.numPlayers
    self.players = {}
    for i = 1, self.numPlayers do
      self.players[i] = BoardPlayer.new(i, playerOrigins[i], i == game.selfPlayer)
    end
  end

  if self.curPlayer == nil then
    self.curPlayer = 1
  end

  self.state = "fadein"
  self.statet = 0
end

function BoardGame:unload()
  if not (self.assets == nil) then
    self.assets.bgm:stop()
    self.assets.walk:stop()
  end
end

function BoardGame:setstate(state)
  self.state = state
  self.statet = 0
end

function BoardGame:setuproll()
  self.cursorpos = 0
  self.greenpos = math.round(love.math.random(1, 100 - goodhitLen))
  self.redpos = self.greenpos
  while (self.redpos >= self.greenpos and self.redpos - self.greenpos < goodhitLen) or (self.greenpos >= self.redpos and self.greenpos - self.redpos < badhitLen) do
    self.redpos = math.round(love.math.random(1, 100 - badhitLen))
  end
end

function BoardGame:panToPlayer(duration)
  local coords = self.players[self.curPlayer]:getMapCoords(self.assets.tileset)
  coords.x = coords.x + self.assets.tileset.tilew / 2
  coords.y = coords.y + self.assets.tileset.tileh / 2 - 40
  self.camera:panToCoords(coords, duration or 3)
end

function BoardGame:update(dt)
  if game.locality == "remote" then
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
        if data.message == "playerHopNearby" then
          self.players[data.player]:forceIdle()
          self.players[data.player]:hopNearby(self.graph)
        elseif data.message == "playerMove" then
          self.players[data.player]:forceIdle()
          self.players[data.player]:move(self.graph)
        elseif data.message == "playerMoveWithChoice" then
          self.players[data.player]:forceIdle()
          self.players[data.player]:moveWithChoice(self.graph, data.choice)
        elseif data.message == "nextPlayer" then
          self.players[self.curPlayer]:forceIdle()
          self.curPlayer = data.player
          if self.curPlayer == game.selfPlayer then
            self:setstate("nextplayer")
          end
        elseif data.message == "playerGoodHit" then
          game.scores[data.player] = game.scores[data.player] + data.hitval * 100
        elseif data.message == "playerNormalHit" then
          game.scores[data.player] = game.scores[data.player] + data.hitval * 80
        elseif data.message == "playerBadHit" then
          game.scores[data.player] = game.scores[data.player] + data.hitval * 60
        elseif data.message == "fadeout" then
          self:setstate("fadeout")
        elseif data.message == "duel" then
          game.shootPlayers = data.duelPlayers
          self:setstate("duel")
        end
      elseif event.type == "disconnect" then
        game.scene:next(game.menu)
      end
      event = game.host:service()
    end

    if not (self.state == "netwait") and not (self.state == "fadeout") and not (self.state == "duel") and not (self.state == "duelfadeout") then
      if not (self.curPlayer == game.selfPlayer) then
        self:setstate("netwait")
      end
    end
  end

  local oldState = self.state

  if self.state == "fadein" then
    if self.statet == 0 then
      self:panToPlayer(1)
    end
    if self.statet >= 1 then
      if self.returnstate then
        self:setstate(self.returnstate)
        self.returnstate = nil
      else
        self:setstate("nextplayer")
      end
    end
  elseif self.state == "nextplayer" then
    if self.statet == 0 then
      self:panToPlayer()
    end
    if self.statet >= 1 then
      self:setstate("waitplayer")
    end
  elseif self.state == "waitplayer" then
    if self.players[self.curPlayer].human then
      if game.input.p[1].a == -1 or game.input.p[1].b == -1 then
        self:setstate("waitfade")
      end
    else
      if self.statet >= 1 then
        self:setstate("waitfade")
      end
    end
  elseif self.state == "netwait" then
    local player = self.players[self.curPlayer]
    local coords = player:getMapCoords(self.assets.tileset)
    coords.x = coords.x + self.assets.tileset.tilew / 2
    coords.y = coords.y + self.assets.tileset.tileh / 2 - 40
    self.camera:setCoords(coords)
    self.players[self.curPlayer]:update(dt)
  elseif self.state == "waitfade" then
    if self.statet >= 1 then
      self:setstate("rollenter")
      self:setuproll()
    end
  elseif self.state == "rollenter" then
    self.cursorpos = self.statet * 100
    if self.statet >= 1 then
      self:setstate("roll")
    end
  elseif self.state == "roll" then
    if self.players[self.curPlayer].human then
      -- human
      if game.input.p[1].a == 1 then
        if self.cursorpos > self.greenpos and self.cursorpos < self.greenpos + goodhitLen then
          self.assets.goodhit:play()
          self.hittype = "good"
          self.hitval = love.math.random(7, 15)
          game.scores[self.curPlayer] = game.scores[self.curPlayer] + self.hitval * 100
          if game.locality == "remote" then
            game.host:broadcast(json.encode({message = "playerGoodHit", player = self.curPlayer, hitval = self.hitval}))
          end
        elseif self.cursorpos > self.redpos and self.cursorpos < self.redpos + badhitLen then
          self.assets.badhit:play()
          self.hittype = "bad"
          self.hitval = love.math.random(1, 3)
          game.scores[self.curPlayer] = game.scores[self.curPlayer] + self.hitval * 60
          if game.locality == "remote" then
            game.host:broadcast(json.encode({message = "playerBadHit", player = self.curPlayer, hitval = self.hitval}))
          end
        else
          self.assets.normalhit:play()
          self.hittype = "normal"
          self.hitval = love.math.random(3, 7)
          game.scores[self.curPlayer] = game.scores[self.curPlayer] + self.hitval * 80
          if game.locality == "remote" then
            game.host:broadcast(json.encode({message = "playerNormalHit", player = self.curPlayer, hitval = self.hitval}))
          end
        end
        self:setstate("rollhit")
      else
        self.cursorpos = 50 * math.cos(self.statet * 5) + 50
      end
    else
      -- ai
      if love.math.random(1, 50) == 1 then
        if self.cursorpos > self.greenpos and self.cursorpos < self.greenpos + goodhitLen then
          self.assets.goodhit:play()
          self.hittype = "good"
          self.hitval = love.math.random(7, 15)
          game.scores[self.curPlayer] = game.scores[self.curPlayer] + self.hitval * 100
          if game.locality == "remote" then
            game.host:broadcast(json.encode({message = "playerGoodHit", player = self.curPlayer, hitval = self.hitval}))
          end
        elseif self.cursorpos > self.redpos and self.cursorpos < self.redpos + badhitLen then
          self.assets.badhit:play()
          self.hittype = "bad"
          self.hitval = love.math.random(1, 3)
          game.scores[self.curPlayer] = game.scores[self.curPlayer] + self.hitval * 60
          if game.locality == "remote" then
            game.host:broadcast(json.encode({message = "playerBadHit", player = self.curPlayer, hitval = self.hitval}))
          end
        else
          self.assets.normalhit:play()
          self.hittype = "normal"
          self.hitval = love.math.random(3, 7)
          game.scores[self.curPlayer] = game.scores[self.curPlayer] + self.hitval * 80
          if game.locality == "remote" then
            game.host:broadcast(json.encode({message = "playerNormalHit", player = self.curPlayer, hitval = self.hitval}))
          end
        end
        self:setstate("rollhit")
      else
        self.cursorpos = 50 * math.cos(self.statet * 5) + 50
      end
    end
  elseif self.state == "rollhit" then
    if self.statet >= 2 then
      self:setstate("move")
    end
  elseif self.state == "move" then
    local player = self.players[self.curPlayer]
    local status = player:getStatus(self.graph)
    if self.hitval > 0 or status == "busy" then
      if status == "hop" then
        self.assets.jump:play()
        player:hopNearby(self.graph)
        self.hitval = self.hitval - 1
        if game.locality == "remote" then
          game.host:broadcast(json.encode({message = "playerHopNearby", player = self.curPlayer}))
        end
      elseif status == "move" then
        self.assets.walk:play()
        player:move(self.graph)
        if game.locality == "remote" then
          game.host:broadcast(json.encode({message = "playerMove", player = self.curPlayer}))
        end
        self.hitval = self.hitval - 1

        if not (player.x1 == player.x and player.y1 == player.y) then
          local duelPlayers = nil
          for i, other in pairs(self.players) do
            if player.x1 == other.x and player.y1 == other.y then
              if duelPlayers == nil then
                duelPlayers = {}
                duelPlayers[self.curPlayer] = {}
              end
              duelPlayers[i] = {}
            end
          end
          if duelPlayers then
            if game.locality == "remote" then
              game.host:broadcast(json.encode({message = "duel", duelPlayers = duelPlayers}))
            end
            game.shootPlayers = duelPlayers
            self:setstate("duel")
          end
        end
      elseif status == "pick" then
        self.assets.walk:stop()
        self.pickchoices = player:getPickChoices(self.graph)
        self:setstate("pickmove")
      elseif status == "busy" then
        player:update(dt)
      end
      local coords = player:getMapCoords(self.assets.tileset)
      coords.x = coords.x + self.assets.tileset.tilew / 2
      coords.y = coords.y + self.assets.tileset.tileh / 2 - 40
      self.camera:setCoords(coords)
    else
      self.assets.walk:stop()
      self:setstate("moveend")
    end
  elseif self.state == "pickmove" then
    local player = self.players[self.curPlayer]
    if player.human then
      if game.input.p[1].r == 1 and self.pickchoices.right then
        player:moveWithChoice(self.graph, "right")
        self.assets.walk:play()
        self:setstate("move")
        self.hitval = self.hitval - 1
        if game.locality == "remote" then
          game.host:broadcast(json.encode({message = "playerMoveWithChoice", player = self.curPlayer, choice = "right"}))
        end
      elseif game.input.p[1].d == 1 and self.pickchoices.down then
        player:moveWithChoice(self.graph, "down")
        self.assets.walk:play()
        self:setstate("move")
        self.hitval = self.hitval - 1
        if game.locality == "remote" then
          game.host:broadcast(json.encode({message = "playerMoveWithChoice", player = self.curPlayer, choice = "down"}))
        end
      elseif game.input.p[1].l == 1 and self.pickchoices.left then
        player:moveWithChoice(self.graph, "left")
        self.assets.walk:play()
        self:setstate("move")
        self.hitval = self.hitval - 1
        if game.locality == "remote" then
          game.host:broadcast(json.encode({message = "playerMoveWithChoice", player = self.curPlayer, choice = "left"}))
        end
      elseif game.input.p[1].u == 1 and self.pickchoices.up then
        player:moveWithChoice(self.graph, "up")
        self.assets.walk:play()
        self:setstate("move")
        self.hitval = self.hitval - 1
        if game.locality == "remote" then
          game.host:broadcast(json.encode({message = "playerMoveWithChoice", player = self.curPlayer, choice = "up"}))
        end
      end
    else
      if self.statet > 1 then
        local choices = {"right", "down", "left", "up"}
        local choice = nil
        while self.pickchoices[choice] == nil do
          choice = choices[love.math.random(1, 4)]
        end
        player:moveWithChoice(self.graph, choice)
        self.assets.walk:play()
        self:setstate("move")
        self.hitval = self.hitval - 1
        if game.locality == "remote" then
          game.host:broadcast(json.encode({message = "playerMoveWithChoice", player = self.curPlayer, choice = choice}))
        end
      end
    end
  elseif self.state == "moveend" then
    if self.statet >= 1 then
      if self.curPlayer < self.numPlayers then
        self.curPlayer = self.curPlayer + 1
        self:setstate("nextplayer")
        if game.locality == "remote" then
          game.host:broadcast(json.encode({message = "nextPlayer", player = self.curPlayer}))
        end
      else
        self:setstate("fadeout")
        if game.locality == "remote" then
          game.host:broadcast(json.encode({message = "fadeout"}))
        end
      end
    end
  elseif self.state == "duel" then
    if self.statet >= 3 then
      self:setstate("duelfadeout")
    end
    self.players[self.curPlayer]:update(dt)
  elseif self.state == "duelfadeout" then
    if self.statet >= 1 then
      if self.locality == "remote" then
        if self.curPlayer == game.selfPlayer then
          self.returnstate = "move"
        else
          self.returnstate = "netwait"
        end
      else
        self.returnstate = "move"
      end
      game.scene:next(game.shoot)
    end
    self.assets.bgm:setVolume(1 - self.statet)
  elseif self.state == "fadeout" then
    if self.statet >= 1 then
      if game.turn == game.numTurns then
        game.scene:next(game.results)
      end

      -- Increment turn counter.
      game.turn = game.turn + 1

      -- Switch board game back to player 1.
      self.curPlayer = 1
      self.returnstate = "waitplayer"

      -- Switch to shoot game with all players.
      game.shootPlayers = {}
      for i = 1, game.numPlayers do
        game.shootPlayers[i] = {}
      end
      game.scene:next(game.shoot)
    end
    self.assets.bgm:setVolume(1 - self.statet)
  end

  self.camera:update(dt)
  self.t = self.t + dt

  -- do not increment statet for new states.
  if self.state == oldState then
    self.statet = self.statet + dt
  end
end

function BoardGame:drawstart(a)
  local str = string.format("Player %d GO! (Turn %d of %d)", self.curPlayer, game.turn, game.numTurns)
  local yoff = math.round(math.sin(self.t) * 10)
  a = math.round(a * 8) / 8
  love.graphics.setColor(0, 0, 0, a / 2)
  love.graphics.rectangle("fill", 0, 39 + yoff, game.canvasw, 45 - math.cos(self.t) * 5)
  yoff = math.round(math.sin(self.t + 0.5) * 10)
  love.graphics.setColor(1, 1, 1, a)
  love.graphics.rectangle("fill", 0, 45 + yoff, game.canvasw, 30)
  yoff = math.round(math.sin(self.t + 1) * 10)
  love.graphics.print(str, 10, 50 + yoff)
end

function BoardGame:drawroll(a, hit)
  local str = string.format("Player %d", self.curPlayer)
  yoff = math.round((-math.sin(math.pi * a)) * 20) * 2
  a = math.round(a * 8) / 8

  local border = 2
  local margin = 6

  local outsidex = margin
  local outsidey = 100 + margin
  local outsidew = game.canvasw - outsidex - margin
  local outsideh = 36

  local insidex = margin + border
  local insidey = 100 + margin + border
  local insidew = game.canvasw - insidex - margin - border
  local insideh = 30

  local barscale = insidew / 100

  love.graphics.setColor(1, 1, 1, a)
  love.graphics.print(str, 10, 30 - yoff)
  love.graphics.setColor(0, 0, 0, a)
  love.graphics.rectangle("fill", insidex, outsidey - yoff, insidew, border) --top
  love.graphics.rectangle("fill", outsidex, outsidey - yoff, border, outsideh) --left
  love.graphics.rectangle("fill", insidex, outsidey + outsideh - border * 2 - yoff, insidew, border * 2) --bottom
  love.graphics.rectangle("fill", outsidex + outsidew - border, outsidey - yoff, border, outsideh) --right
  love.graphics.setColor(1, 1, 1, a / 2)
  love.graphics.rectangle("fill", insidex, insidey - yoff, insidew, insideh)
  love.graphics.setColor(0, 1, 0, a)
  love.graphics.rectangle("fill", insidex + self.greenpos * barscale, insidey - yoff, goodhitLen * barscale, insideh)
  love.graphics.setColor(1, 0, 0, a)
  love.graphics.rectangle("fill", insidex + self.redpos * barscale, insidey - yoff, badhitLen * barscale, insideh)

  -- it's kinda cool if the cursor stays in place during the hit anim
  if hit then
    yoff = 0
  end

  love.graphics.setColor(0, 0, 0, a)
  love.graphics.rectangle("fill", insidex + self.cursorpos * barscale, outsidey - yoff, 1, outsideh)
  love.graphics.setColor(1, 1, 1, a)
  love.graphics.draw(self.assets.cursorimg, insidex + self.cursorpos * barscale - 4, outsidey + outsideh - yoff)
end

function BoardGame:drawhit(a)
  local str = string.format("%d", self.hitval)
  love.graphics.setColor(1, 1, 1, a)
  love.graphics.printf(str, 0, game.canvash / 2 - 40, game.canvasw, "center")
end

function BoardGame:drawScore(yoff)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(string.format("Score: %d", game.scores[self.curPlayer]), 10, 10 + yoff)
end

function BoardGame:draw()
  local screenshake = 0
  love.graphics.setCanvas(game.canvas)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.clear(0.5, 0.5, 0.5, 1)
  love.graphics.setBlendMode("alpha")

  local mx = self.camera:getMapX()
  local my = self.camera:getMapY()

  self.assets.tileset:drawMap(self.assets.map, mx, my)
  for i = 1, self.numPlayers do
    self.players[i]:draw(self.assets.tileset, mx, my)
  end

  if self.state == "fadein" then
    local a = math.round((1 - self.statet) * 8) / 8
    love.graphics.setColor(0, 0, 0, a)
    love.graphics.rectangle("fill", 0, 0, game.canvasw, game.canvash)
  elseif self.state == "nextplayer" then
    self:drawstart(self.statet)
  elseif self.state == "waitplayer" then
    self:drawstart(1)
    self:drawScore(0)
  elseif self.state == "netwait" then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Player %d is playing.", self.curPlayer), 10, 10)
    self:drawScore(20)
  elseif self.state == "waitfade" then
    self:drawstart(1 - self.statet)
    self:drawScore(0)
  elseif self.state == "rollenter" then
    self:drawroll(self.statet, false)
    self:drawScore(0)
  elseif self.state == "roll" then
    self:drawroll(1, false)
    self:drawScore(0)
  elseif self.state == "rollhit" then
    self:drawroll(1 - self.statet, true)
    self:drawhit(1)
    self:drawScore(0)
    local a = math.round((1 - self.statet) * 8) / 8
    if self.hittype == "good" then
      love.graphics.setColor(0.5, 1, 0.5, a)
      screenshake = (1 - self.statet) * 15
    elseif self.hittype == "bad" then
      love.graphics.setColor(1, 0.5, 0.5, a)
      screenshake = (1 - self.statet) * 5
    else
      love.graphics.setColor(1, 1, 1, a)
      screenshake = (1 - self.statet) * 10
    end
    love.graphics.rectangle("fill", 0, 0, game.canvasw, game.canvash)
  elseif self.state == "move" then
    self:drawhit(1)
    self:drawScore(0)
  elseif self.state == "pickmove" then
    local player = self.players[self.curPlayer]
    local coords = player:getMapCoords(self.assets.tileset)
    if self.pickchoices.right then self.assets.tileset:drawTile(coords.x + mx + 32, coords.y + my - 16, 53) end
    if self.pickchoices.down then self.assets.tileset:drawTile(coords.x + mx, coords.y + my + 16, 54) end
    if self.pickchoices.left then self.assets.tileset:drawTile(coords.x + mx - 32, coords.y + my - 16, 55) end
    if self.pickchoices.up then self.assets.tileset:drawTile(coords.x + mx, coords.y + my - 48, 56) end
    self:drawScore(0)
  elseif self.state == "duel" then
    if self.statet < 1 then
      local a = math.round((1 - self.statet) * 8) / 8
      love.graphics.setColor(1, 1, 1, a)
      love.graphics.rectangle("fill", 0, 0, game.canvasw, game.canvash)
    end
    local str = string.format("DUEL!", self.hitval)
    love.graphics.setColor(math.sin(self.statet / 5) * 0.5 + 0.5, math.cos(self.statet / 4) * 0.5 + 0.5, math.sin(self.statet / 3) * 0.5 + 0.5, a)
    love.graphics.printf(str, 0, game.canvash / 2, game.canvasw, "center")
  elseif self.state == "duelfadeout" then
    local a = math.round(self.statet * 8) / 8
    love.graphics.setColor(0, 0, 0, a)
    love.graphics.rectangle("fill", 0, 0, game.canvasw, game.canvash)
  elseif self.state == "fadeout" then
    local a = math.round(self.statet * 8) / 8
    love.graphics.setColor(0, 0, 0, a)
    love.graphics.rectangle("fill", 0, 0, game.canvasw, game.canvash)
  end
  local t = self.t

  love.graphics.setCanvas()
  love.graphics.setColor(1, 1, 1, 1)
  local x = 0
  local y = 0
  if screenshake > 0 then
    x = math.random() * screenshake - screenshake / 2
    y = math.random() * screenshake - screenshake / 2
  end
  love.graphics.draw(game.canvas, x, y, 0, game.canvasscale)
end

return BoardGame
