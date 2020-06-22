SceneManager = require("sceneman")
InputManager = require("inputman")
BoardGame = require("boardgame")
ShootGame = require("shootgame")

-- game global
game = {
  canvas = nil,
  winw = 320 * 2,
  winh = 288 * 2,
  canvasw = 320,
  canvash = 288,
  canvasscale = 2,
  numPlayers = 2,
  scene = SceneManager.new(),
  input = InputManager.new(),
  board = BoardGame.new(),
  shoot = ShootGame.new(),
}

splash = require("splash")

function math.round(n, deci)
  deci = 10^(deci or 0)
  return math.floor(n*deci+.5)/deci
end

function love.load()
  font = love.graphics.newImageFont("gfx/font.png",
  " abcdefghijklmnopqrstuvwxyz" ..
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
  "123456789.,!?-+/():;%&`'*#=[]\"")
  love.graphics.setFont(font)

  love.window.setMode(game.winw, game.winh, {resizable=false, vsync=true})
  love.graphics.setDefaultFilter("nearest", "nearest", 0)

  game.canvas = love.graphics.newCanvas(game.canvasw, game.canvash)

  -- Set initial state.
  --game.scene:next(splash)
  game.scene:next(game.board)
end

function love.keypressed(key, scancode, isrepeat)
  game.input:onKeyPressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
  game.input:onKeyReleased(key, scancode)
end

function love.update(dt)
  game.scene:update(dt)
  game.input:update(dt)
end

function love.draw()
  love.graphics.clear(1, 1, 1)
  love.graphics.setColor(1, 1, 1, 1)
  game.scene:draw()
end
