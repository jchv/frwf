local JoinGameMenu = {}
JoinGameMenu.__index = JoinGameMenu

function JoinGameMenu.new()
  local menu = {}
  setmetatable(menu, JoinGameMenu)
  menu.log = {}
  return menu
end

function JoinGameMenu:load()
  self.connectAddr = ""
  love.keyboard.setTextInput(true)
  self.statet = 0
  self.state = "enterip"
end

function JoinGameMenu:unload()
  love.keyboard.setTextInput(false)
end

function JoinGameMenu:setState(state)
  self.state = state
  self.statet = 0
end

function JoinGameMenu:addLogMessage(log)
  table.insert(self.log, log)
  if table.getn(self.log) > 10 then 
    table.remove(self.log, 1)
  end
end

function JoinGameMenu:onKeyPressed(key)
  if self.state == "enterip" then
    if key == "return" then
      game.join(self.connectAddr .. ":10305")
      self:setState("join")
    elseif key == "backspace" then
      self.connectAddr = string.sub(self.connectAddr, 1, string.len(self.connectAddr) - 1)
    end
  end
end

function JoinGameMenu:textInput(t)
  if self.state == "enterip" then
    self.connectAddr = string.gsub(self.connectAddr .. t, "[^0-9a-z.]", "")
  end
end

function JoinGameMenu:update(dt)
  if self.state == "join" then
    local event = game.host:service(100)
    while event do
      if event.type == "receive" then
        self:addLogMessage("Got message: " .. event.data .. ", " .. event.peer:connect_id())
        data = json.decode(event.data)
        if data.message == "startgame" then
          game.locality = "remote"
          game.scene:next(game.board)
        elseif data.message == "setplayer" then
          game.selfPlayer = data.player
          game.setNumPlayers(data.numPlayers)
        end
      elseif event.type == "connect" then
        self:addLogMessage(event.peer:connect_id() .. " connected.")
      elseif event.type == "disconnect" then
        self:addLogMessage(event.peer:connect_id() .. " disconnected.")
      end
      event = game.host:service()
    end
  end
end

function JoinGameMenu:draw()
  if self.state == "enterip" then
    love.graphics.print("Enter address to connect to.", 50, 200)
    love.graphics.print(self.connectAddr, 60, 220)
  elseif self.state == "join" then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Joining server " .. self.connectAddr .. " on port 10305.", 50, 200)
    for i, log in pairs(self.log) do
      love.graphics.print(log, 60, 220 + 20 * i)
    end
  end
end

return JoinGameMenu
