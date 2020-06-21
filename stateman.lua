local StateManager = {}
StateManager.__index = StateManager

function StateManager.new(first)
  local stateman = {}
  setmetatable(stateman, StateManager)
  return stateman
end

function StateManager:next(next)
  self.scene = next
  self.scene.load()
end

function StateManager:update(dt)
  self.scene.update(dt)
end

function StateManager:draw()
  self.scene.draw()
end

return StateManager
