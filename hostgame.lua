local HostGameMenu = {}
HostGameMenu.__index = HostGameMenu

function HostGameMenu.new()
  local menu = {}
  setmetatable(menu, HostGameMenu)
  menu.log = {}
  return menu
end

function HostGameMenu:load()
  game.host("localhost:10305")
end

function HostGameMenu:unload()
end

function HostGameMenu:addLogMessage(log)
  table.insert(self.log, log)
  if table.getn(self.log) > 10 then 
    table.remove(self.log, 1)
  end
end

function HostGameMenu:update(dt)
  local event = game.host:service(100)
  while event do
    if event.type == "receive" then
      self:addLogMessage("Got message: " .. event.data .. ", " .. event.peer:connect_id())
    elseif event.type == "connect" then
      game.numPeers = game.numPeers + 1
      local player = game.numPeers + 1
      game.peerPlayers[player] = event.peer
      event.peer:send(json.encode({message = "setplayer", player = player, numPlayers = game.numPlayers}))
      self:addLogMessage(event.peer:connect_id() .. " connected as player " .. player)
    elseif event.type == "disconnect" then
      game.numPeers = game.numPeers - 1
      self:addLogMessage(event.peer:connect_id() .. " disconnected.")
      table.remove(game.peerPlayers, player)
    end
    event = game.host:service()
  end
end

function HostGameMenu:draw()
  love.graphics.setColor(1, 1, 1, 1)
  if game.numPeers < game.numPlayers - 1 then
    love.graphics.print("You are player 1.", 50, 200)
    love.graphics.print("Waiting for players (" .. (game.numPlayers - game.numPeers - 1) .. ")", 50, 220)
    for i, log in pairs(self.log) do
      love.graphics.print(log, 60, 220 + 20 * i)
    end
  else
    game.selfPlayer = 1
    game.locality = "remote"
    game.host:broadcast(json.encode({message = "startgame"}))
    self:update(0)
    game.scene:next(game.board)
  end
end

return HostGameMenu
