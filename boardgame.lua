local boardgame = {}
local map = require("map")

-- gfx
local tileset = nil
local cursorimg = nil

-- sfx
local normalhit = nil
local goodhit = nil
local badhit = nil

-- data
local boredisle = require("boredisle")
local camera = map.newCamera(0, 0)

function boardgame.load()
  boardgame.t = 0
  boardgame.state = "fadein"
  boardgame.statet = 0
  boardgame.player = 1

  tileset = map.loadtiles("tileset.png", 32, 32)
  cursorimg = love.graphics.newImage("cursor.png")

  normalhit = love.audio.newSource("normalhit.wav", "static")
  goodhit = love.audio.newSource("goodhit.wav", "static")
  badhit = love.audio.newSource("badhit.wav", "static")

  bgm = love.audio.newSource("nihilism.wav", "stream")
  bgm:setLooping(true)
  bgm:play()
end

function boardgame.setstate(state)
  boardgame.state = state
  boardgame.statet = 0
end

function boardgame.setuproll()
  boardgame.cursorpos = 0
  boardgame.greenpos = math.round(love.math.random(1, 142 - 8))
  boardgame.redpos = boardgame.greenpos
  while math.abs(boardgame.redpos - boardgame.greenpos) < 8 do
    boardgame.redpos = math.round(love.math.random(1, 142 - 8))
  end
end

function boardgame.update(dt)
  camera:update(dt)
  boardgame.t = boardgame.t + dt
  boardgame.statet = boardgame.statet + dt

  if boardgame.state == "fadein" then
    if boardgame.statet >= 1 then
      boardgame.setstate("nextplayer")
    end
  elseif boardgame.state == "nextplayer" then
    if boardgame.statet >= 1 then
      boardgame.setstate("waitplayer")
      camera:panToCoords(6 * 32 + 16, 8 * 32 + 16)
    end
  elseif boardgame.state == "waitplayer" then
    if input.p[boardgame.player].a == -1 or input.p[boardgame.player].b == -1 then
      boardgame.setstate("waitfade")
    end
  elseif boardgame.state == "waitfade" then
    if boardgame.statet >= 1 then
      boardgame.setstate("rollenter")
      boardgame.setuproll()
    end
  elseif boardgame.state == "rollenter" then
    if boardgame.statet >= 1 then
      boardgame.setstate("roll")
    end
    boardgame.cursorpos = boardgame.statet * 142
  elseif boardgame.state == "roll" then
    if input.p[boardgame.player].a == 1 then
      if boardgame.cursorpos > boardgame.greenpos and boardgame.cursorpos < boardgame.greenpos + 8 then
        goodhit:play()
        boardgame.hittype = "good"
        boardgame.hitval = love.math.random(7, 10)
      elseif boardgame.cursorpos > boardgame.redpos and boardgame.cursorpos < boardgame.redpos + 8 then
        badhit:play()
        boardgame.hittype = "bad"
        boardgame.hitval = love.math.random(1, 3)
      else
        normalhit:play()
        boardgame.hittype = "normal"
        boardgame.hitval = love.math.random(3, 7)
      end
      boardgame.setstate("rollhit")
    else
      boardgame.cursorpos = 71 * math.cos(boardgame.statet * 5) + 71
    end
  elseif boardgame.state == "rollhit" then
    if boardgame.statet >= 2 then
      boardgame.setstate("move")
    end
  elseif boardgame.state == "move" then
    if boardgame.statet >= 1 then
      boardgame.statet = 0
      if boardgame.hitval >= 1 then
        boardgame.hitval = boardgame.hitval - 1
      else
        boardgame.setstate("moveend")
      end
    end
  elseif boardgame.state == "moveend" then
    if boardgame.statet >= 1 then
      if boardgame.player < 4 then
        boardgame.player = boardgame.player + 1
        boardgame.setstate("nextplayer")
      else
        boardgame.setstate("selectgame")
      end
    end
  end
end

function boardgame.drawstart(a)
  local str = string.format("Player %d GO!", boardgame.player)
  local yoff = math.round(math.sin(boardgame.t) * 10)
  a = math.round(a * 8) / 8
  love.graphics.setColor(0, 0, 0, a / 2)
  love.graphics.rectangle("fill", 0, 39 + yoff, 160, 45 - math.cos(boardgame.t) * 5)
  yoff = math.round(math.sin(boardgame.t + 0.5) * 10)
  love.graphics.setColor(1, 1, 1, a)
  love.graphics.rectangle("fill", 0, 45 + yoff, 160, 30)
  yoff = math.round(math.sin(boardgame.t + 1) * 10)
  love.graphics.print(str, 10, 50 + yoff)
end

function boardgame.drawroll(a, hit)
  local str = string.format("Player %d", boardgame.player)
  yoff = math.round((-math.sin(math.pi * a)) * 20) * 2
  a = math.round(a * 8) / 8
  love.graphics.setColor(1, 1, 1, a)
  love.graphics.print(str, 10, 10 - yoff)
  love.graphics.setColor(0, 0, 0, a)
  love.graphics.rectangle("fill", 6, 50 - yoff, 146, 18)
  love.graphics.setColor(1, 1, 1, a)
  love.graphics.rectangle("fill", 8, 52 - yoff, 142, 14)
  love.graphics.setColor(0, 1, 0, a)
  love.graphics.rectangle("fill", 8 + boardgame.greenpos, 52 - yoff * 2, 8, 14)
  love.graphics.setColor(1, 0, 0, a)
  love.graphics.rectangle("fill", 8 + boardgame.redpos, 52 + yoff, 8, 14)

  -- it's kinda cool if the cursor stays in place during the hit anim
  if hit then
    yoff = 0
  end

  love.graphics.setColor(0, 0, 0, a)
  love.graphics.rectangle("fill", 8 + boardgame.cursorpos, 50 - yoff, 1, 18)
  love.graphics.setColor(1, 1, 1, a)
  love.graphics.draw(cursorimg, 4 + boardgame.cursorpos, 68 - yoff)
end

function boardgame.drawhit(a)
  local str = string.format("%d", boardgame.hitval)
  love.graphics.setColor(1, 1, 1, a)
  love.graphics.printf(str, 0, 50, 160, "center")
end

function boardgame.draw()
  local screenshake = 0
  love.graphics.setCanvas(canvas)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.clear(0.5, 0.5, 0.5, 1)
  love.graphics.setBlendMode("alpha")

  map.drawmap(boredisle, tileset, camera:getMapX(), camera:getMapY())

  if boardgame.state == "fadein" then
    local a = math.round((1 - boardgame.statet) * 8) / 8
    love.graphics.setColor(0, 0, 0, a)
    love.graphics.rectangle("fill", 0, 0, 160, 144)
  elseif boardgame.state == "nextplayer" then
    boardgame.drawstart(boardgame.statet)
  elseif boardgame.state == "waitplayer" then
    boardgame.drawstart(1)
  elseif boardgame.state == "waitfade" then
    boardgame.drawstart(1 - boardgame.statet)
  elseif boardgame.state == "rollenter" then
    boardgame.drawroll(boardgame.statet, false)
  elseif boardgame.state == "roll" then
    boardgame.drawroll(1, false)
  elseif boardgame.state == "rollhit" then
    boardgame.drawroll(1 - boardgame.statet, true)
    boardgame.drawhit(1)
    local a = math.round((1 - boardgame.statet) * 8) / 8
    if boardgame.hittype == "good" then
      love.graphics.setColor(0.5, 1, 0.5, a)
      screenshake = (1 - boardgame.statet) * 15
    elseif boardgame.hittype == "bad" then
      love.graphics.setColor(1, 0.5, 0.5, a)
      screenshake = (1 - boardgame.statet) * 5
    else
      love.graphics.setColor(1, 1, 1, a)
      screenshake = (1 - boardgame.statet) * 10
    end
    love.graphics.rectangle("fill", 0, 0, 160, 144)
  elseif boardgame.state == "move" then
    boardgame.drawhit(1)
  elseif boardgame.state == "selectgame" then
  end
  local t = boardgame.t

  love.graphics.setCanvas()
  love.graphics.setColor(1, 1, 1, 1)
  local x = 0
  local y = 0
  if screenshake > 0 then
    x = math.random() * screenshake - screenshake / 2
    y = math.random() * screenshake - screenshake / 2
  end
  love.graphics.draw(canvas, x, y, 0, 2)
end

return boardgame
