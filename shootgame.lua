local TileSet = require("tileset")
local Camera = require("camera")
local ShootPlayer = require("shootplayer")

local ShootGame = {}
ShootGame.__index = ShootGame

function ShootGame.new()
  local shootgame = {
    t = 0,
    state = "fadein",
    statet = 0,
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

    -- bgm
    self.assets.bgm = love.audio.newSource("bgm/battleground.wav", "stream")
    self.assets.bgm:setLooping(true)
    self.assets.bgm:play()
    
    -- data
    self.assets.map = require("data/battleground.map")
  end

  self.camera = Camera.new(32 * 32, 78 * 32)

  local playerOrigins = self.assets.tileset:getPlayerOrigins(self.assets.map)
  self.curPlayer = 1
  self.numPlayers = game.numPlayers
  self.players = {}
  for i = 1, self.numPlayers do
    self.players[i] = ShootPlayer.new(i, playerOrigins[i], self)
  end
end

function ShootGame:unload()
  if not (self.assets == nil) then
    self.assets.bgm:stop()
  end
end

function ShootGame:update(dt)
  for i = 1, self.numPlayers do
    self.players[i]:update(dt)
  end

  self.camera:setCoords({x = self.players[1].x, y = self.players[1].y})
end

function ShootGame:draw()
  local screenshake = 0
  love.graphics.setCanvas(game.canvas)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.clear(0.5, 0.5, 0.5, 1)
  love.graphics.setBlendMode("alpha")

  local mx = self.camera:getMapX()
  local my = self.camera:getMapY()

  self.assets.tileset:drawMap(self.assets.map, mx, my)
  for i = 1, self.numPlayers do
    self.players[i]:draw(mx, my)
  end

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

return ShootGame