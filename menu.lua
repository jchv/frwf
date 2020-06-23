local Menu = {}
Menu.__index = Menu

function Menu.new()
  local menu = {}
  setmetatable(menu, Menu)
  return menu
end

function Menu:load()
  self.statet = 0
  self.state = "fadeinbg"
  self.bg = love.graphics.newImage("gfx/menu.png")
  self.bgm = love.audio.newSource("bgm/nihilists.wav", "static")
  self.bgm:setLooping(true)
  self.bgm:setVolume(0)
  self.bgm:play()
  self.intro = love.audio.newSource("sfx/intro.wav", "static")
  self.selection = 0
  self.numPlayers = 2
end

function Menu:unload()
  self.bgm:stop()
end

function Menu:setState(state)
  self.state = state
  self.statet = 0
end

function Menu:update(dt)
  local oldState = self.state

  if self.state == "fadeinbg" then
    if self.statet < 1 then
      self.bgm:setVolume(self.statet)
    else
      self.bgm:setVolume(1)
    end

    if self.statet > 3 then
      self:setState("fadeinmenu")
    end
  elseif self.state == "fadeinmenu" then
    if self.statet > 1 then
      self:setState("selecting")
    end
  elseif self.state == "selecting" then
    if game.input.p[1].u == 1 or game.input.p[1].u > 10 and game.input.p[1].u % 10 == 1 then
      self.selection = self.selection - 1
    elseif game.input.p[1].d == 1 or game.input.p[1].d > 10 and game.input.p[1].d % 10 == 1 then
      self.selection = self.selection + 1
    end
  
    if self.selection < 0 then
      self.selection = 4
    elseif self.selection > 4 then
      self.selection = 0
    end

    if game.input.p[1].a == 1 then
      self:setState("fadeoutmenu")
    end
  elseif self.state == "fadeoutmenu" then
    if self.statet > 1 then
      if self.selection == 0 or self.selection == 1 or self.selection == 2 then
        self:setState("fadeinsetplayers")
      else
        self:setState("fadeout")
      end
    end
  elseif self.state == "fadeinsetplayers" then
    if self.statet > 1 then
      self:setState("setplayers")
    end
  elseif self.state == "setplayers" then
    if game.input.p[1].u == 1 or game.input.p[1].u > 10 and game.input.p[1].u % 10 == 1 then
      self.numPlayers = self.numPlayers - 1
    elseif game.input.p[1].d == 1 or game.input.p[1].d > 10 and game.input.p[1].d % 10 == 1 then
      self.numPlayers = self.numPlayers + 1
    end
  
    if self.numPlayers < 2 then
      self.numPlayers = 4
    elseif self.numPlayers > 4 then
      self.numPlayers = 2
    end

    if game.input.p[1].a == 1 then
      self:setState("fadeoutsetplayers")
    end
  elseif self.state == "fadeoutsetplayers" then
    if self.statet > 1 then
      self:setState("fadeout")
    end
  elseif self.state == "fadeout" then
    if self.statet > 1 then
      self.bgm:stop()
      if self.selection == 0 then
        game.setNumPlayers(self.numPlayers)
        game.scene:next(game.board)
      elseif self.selection == 1 then
        game.setNumPlayers(self.numPlayers)
        game.turn = 1
        game.numTurns = 0
        game.scene:next(game.shoot)
      elseif self.selection == 2 then
        game.setNumPlayers(self.numPlayers)
        game.scene:next(game.hostgame)
      elseif self.selection == 3 then
        game.scene:next(game.joingame)
      elseif self.selection == 4 then
        love.event.push('quit')
      end
    end
    self.bgm:setVolume(1 - self.statet)
  end


  if self.state == oldState then
    self.statet = self.statet + dt
  end
end

function Menu:drawMenuItems(a, onlysel)
  onlysel = onlysel or false
  love.graphics.setColor(1, 1, 1, a)
  love.graphics.print("-", 10, 200 + 40 * self.selection)
  if not onlysel or self.selection == 0 then love.graphics.print("Single player (with AI)", 50, 200) end
  if not onlysel or self.selection == 1 then love.graphics.print("AI Deathmatch", 50, 240) end
  if not onlysel or self.selection == 2 then love.graphics.print("Host multiplayer game", 50, 280) end
  if not onlysel or self.selection == 3 then love.graphics.print("Join multiplayer game", 50, 320) end
  if not onlysel or self.selection == 4 then love.graphics.print("Quit", 50, 360) end
end

function Menu:drawSetPlayers(a, onlysel)
  onlysel = onlysel or false
  love.graphics.setColor(1, 1, 1, a)
  love.graphics.print("-", 10, 120 + 40 * self.numPlayers)
  if not onlysel or self.numPlayers == 2 then love.graphics.print("2 Players", 50, 200) end
  if not onlysel or self.numPlayers == 3 then love.graphics.print("3 Players", 50, 240) end
  if not onlysel or self.numPlayers == 4 then love.graphics.print("4 Players (recommended)", 50, 280) end
end

function Menu:draw()
  local t = self.statet

  if self.state == "fadeinbg" then
    love.graphics.setColor(1, 1, 1, math.round(t * 8) / 8)
    love.graphics.draw(self.bg, 0, 0)
  elseif self.state == "fadeinmenu" then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.bg, 0, 0)
    self:drawMenuItems(math.round(t * 8) / 8)
  elseif self.state == "selecting" then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.bg, 0, 0)
    self:drawMenuItems(1)
  elseif self.state == "fadeoutmenu" then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.bg, 0, 0)
    self:drawMenuItems(math.round((1 - t) * 8) / 8, true)
  elseif self.state == "fadeinsetplayers" then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.bg, 0, 0)
    self:drawSetPlayers(math.round(t * 8) / 8)
  elseif self.state == "setplayers" then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.bg, 0, 0)
    self:drawSetPlayers(1)
  elseif self.state == "fadeoutsetplayers" then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.bg, 0, 0)
    self:drawSetPlayers(math.round((1 - t) * 8) / 8, true)
  elseif self.state == "fadeout" then
    love.graphics.setColor(1, 1, 1, math.round((1 - t) * 8) / 8)
    love.graphics.draw(self.bg, 0, 0)
  end
end

return Menu
