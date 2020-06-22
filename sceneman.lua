local SceneManager = {}
SceneManager.__index = SceneManager

function SceneManager.new()
  local stateman = {}
  setmetatable(stateman, SceneManager)
  return stateman
end

function SceneManager:next(next)
  if not (self.scene == nil) then
    self.scene:unload()
  end
  self.scene = next
  self.scene:load()
end

function SceneManager:update(dt)
  self.scene:update(dt)
end

function SceneManager:draw()
  self.scene:draw()
end

return SceneManager
