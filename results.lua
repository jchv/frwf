local Results = {}
Results.__index = Results

function Results.new()
  local results = {}
  setmetatable(results, Results)
  return results
end

function Results:load()
  if self.assets == nil then
    self.assets = {}
    self.assets.showpos = love.audio.newSource("sfx/normalhit.wav", "static")
    self.assets.show1st = love.audio.newSource("sfx/kill.wav", "static")
  end
  local positions = {}
  for player, score in pairs(game.scores) do
    table.insert(positions, {
      player = player,
      score = score,
    })
  end
  table.sort(positions, function(a, b) return a.score > b.score end)
  self.positions = positions
  self.statet = 0
  self.state = "fadein"
  self.showgt = game.numPlayers
end

function Results:unload()
end

function Results:setState(state)
  self.state = state
  self.statet = 0
end

function Results:update(dt)
  local oldState = self.state

  if self.state == "fadein" then
    if self.statet > 1 then
      self:setState("animate")
    end
  elseif self.state == "animate" then
    if self.statet > 2 then
      if self.showgt == 0 then
        self:setState("waitinput")
      else
        self.showgt = self.showgt - 1
        if self.showgt == 0 then
          self.assets.show1st:stop()
          self.assets.show1st:play()
        else
          self.assets.showpos:stop()
          self.assets.showpos:play()
        end
        self.statet = 0
      end
    end
  elseif self.state == "waitinput" then
    if game.input.p[1].a > 0 or game.input.p[1].b > 0 then
      self:setState("fadeout")
    end
  elseif self.state == "fadeout" then
    if self.statet > 1 then
      game.scene:next(game.menu)
    end
  end

  if self.state == oldState then
    self.statet = self.statet + dt
  end
end

local playerColor = {
  {0.3, 0.3, 1.0},
  {1.0, 0.3, 0.3},
  {0.8, 0.8, 0.8},
  {0.3, 1.0, 0.3},
}

local place = {"1st", "2nd", "3rd", "4th"}

function Results:draw()
  local screenshake = 0
  love.graphics.setCanvas(game.canvas)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.clear(0.5, 0.5, 0.6, 1)
  love.graphics.setBlendMode("alpha")

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("fill", 0, 0, game.canvasw, 50)
  love.graphics.printf("RESULTS", 0, 20, game.canvasw, "center")

  for i, position in pairs(self.positions) do
    if i > self.showgt then
      local color = playerColor[position.player]
      love.graphics.setColor(color[1], color[2], color[3], 1.0)
      love.graphics.print(string.format("%s - Player %d: %d", place[i], position.player, position.score), 10, 30 + 40 * i)
    end
  end

  if self.state == "fadein" then
    love.graphics.clear(0, 0, 0, 1 - self.statet)
  elseif self.state == "animate" then
    if self.statet < 1 then
      screenshake = (1 - self.statet) * love.math.random() * 10 * (4 - self.showgt)
    end
  elseif self.state == "waitinput" then
    love.graphics.setColor(0.8, 0.8, 0.8, 1.0)
    love.graphics.print("Press A or B to return to menu.", 10, game.canvash - 30 - math.floor(math.sin(self.statet) * 5))
  elseif self.state == "fadeout" then
    love.graphics.setColor(1, 1, 1, self.statet)
    love.graphics.rectangle("fill", 0, 0, game.canvasw, game.canvash)
  end

  love.graphics.setCanvas()
  love.graphics.clear(0.5, 0.5, 0.6, 1)
  love.graphics.setColor(1, 1, 1, 1)
  local x = 0
  local y = 0
  if screenshake > 0 then
    x = math.random() * screenshake - screenshake / 2
    y = math.random() * screenshake - screenshake / 2
  end
  love.graphics.draw(game.canvas, x, y, 0, game.canvasscale)
end

return Results
