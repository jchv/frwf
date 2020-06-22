local splash = {}

local intro = nil
local introplayed = false
local preloser = nil

function splash.load()
  splash.t = 0
  splash.img = love.graphics.newImage("splash.png")
  intro = love.audio.newSource("intro.wav", "static")
  preloser = love.graphics.newQuad(0, 0, 280, splash.img:getHeight(), splash.img:getWidth(), splash.img:getHeight())
end

function splash.update(dt)
  splash.t = splash.t + dt
  if splash.t > 4 and introplayed == false then
    intro:play()
    introplayed = true
  elseif splash.t >= 8 then
    game.scene:next(boardgame)
  end
end

function splash.draw()
  local t = splash.t
  if t < 4 then
      love.graphics.clear(1, 1, 1)
      love.graphics.draw(splash.img, preloser, 0, math.round(t * 72 - 288, 2))
  elseif t < 5 then
      love.graphics.clear(1, 1, 1)
      love.graphics.draw(splash.img, 0, 0)
  elseif t < 6 then
      love.graphics.clear(1, 1, 1)
      love.graphics.setColor(1, 1, 1, math.round((6 - t) * 8) / 8)
      love.graphics.draw(splash.img, 0, 0)
  elseif t < 7 then
      love.graphics.clear(1, 1, 1)
  elseif t < 8 then
      local v = math.round((8 - t) * 8) / 8
      love.graphics.clear(v, v, v)
  end
end

return splash
