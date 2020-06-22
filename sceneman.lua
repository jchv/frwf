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

function SceneManager:textInput(t)
  if self.scene.textInput then
    self.scene:textInput(t)
  end
end

function SceneManager:onKeyPressed(key, scancode, isrepeat)
  if self.scene.onKeyPressed then
    self.scene:onKeyPressed(key, scancode, isrepeat)
  end
end

function SceneManager:update(dt)
  self.scene:update(dt)
end

function SceneManager:draw()
  self.scene:draw()
end

return SceneManager
