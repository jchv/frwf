stateman = require("stateman")
input = require("input")
splash = require("splash")
boardgame = require("boardgame")

function math.round(n, deci)
  deci = 10^(deci or 0)
  return math.floor(n*deci+.5)/deci
end

function love.load()
  font = love.graphics.newImageFont("font.png",
  " abcdefghijklmnopqrstuvwxyz" ..
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
  "123456789.,!?-+/():;%&`'*#=[]\"")
  love.graphics.setFont(font)

  love.window.setMode(320, 288, {resizable=false, vsync=true})
  love.graphics.setDefaultFilter("nearest", "nearest", 0)
  canvas = love.graphics.newCanvas(160, 144)
  stateman.load(splash)
  --stateman.load(boardgame)
end

function love.update(dt)
  stateman.update(dt)
  input.update(dt)
end

function love.draw()
  love.graphics.clear(1, 1, 1)
  love.graphics.setColor(1, 1, 1, 1)
  stateman.draw()
end
