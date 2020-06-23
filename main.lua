enet = require("enet")
json = require("json")
SceneManager = require("sceneman")
InputManager = require("inputman")
BoardGame = require("boardgame")
ShootGame = require("shootgame")
Menu = require("menu")
JoinGameMenu = require("joingame")
HostGameMenu = require("hostgame")
Results = require("results")

-- game global
game = {
  canvas = nil,
  winw = 320 * 2,
  winh = 288 * 2,
  canvasw = 320,
  canvash = 288,
  canvasscale = 2,
  numPlayers = 2,
  peerPlayers = {},
  shootPlayers = {{}, {}},
  scores = {0, 0},
  turn = 1,
  numTurns = 5,
  numPeers = 0,
  selfPlayer = 1,
  locality = "local",
  scene = SceneManager.new(),
  input = InputManager.new(),
  board = BoardGame.new(),
  shoot = ShootGame.new(),
  menu = Menu.new(),
  joingame = JoinGameMenu.new(),
  hostgame = HostGameMenu.new(),
  results = Results.new(),
}

function game.host(address)
  game.host = enet.host_create(address)
end

function game.join(address)
  game.host = enet.host_create()
  game.server = game.host:connect(address)
end

function game.setNumPlayers(numPlayers)
  game.numPlayers = numPlayers
  for i = 1, game.numPlayers do
    game.scores[i] = 0
  end
end

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

  game.scene:next(game.menu)
  --game.scene:next(game.shoot)
end

function love.textinput(t)
  game.scene:textInput(t)
end

function love.keypressed(key, scancode, isrepeat)
  game.scene:onKeyPressed(key, scancode, isrepeat)
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
