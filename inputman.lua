local InputManager = {}
InputManager.__index = InputManager

local buttons = {"a", "b", "u", "d", "l", "r"}
local buttonMap = {
  ["f"] = "a",
  ["g"] = "b",
  ["w"] = "u",
  ["s"] = "d",
  ["a"] = "l",
  ["d"] = "r",
}

function InputManager.new()
  local inputman = {}
  setmetatable(inputman, InputManager)

  inputman.p = {}
  for i = 1, 4 do
    inputman.p[i] = {}
    for n, b in pairs(buttons) do
      inputman.p[i][b] = 0
    end
  end

  return inputman
end

function InputManager:setButtonState(i, button, down)
  if down and self.p[i][button] > 0 then return end
  if not down and self.p[i][button] <= 0 then return end

  if down == true then
    self.p[i][button] = 1
  else
    self.p[i][button] = -1
  end
end

function InputManager:onKeyPressed(key, scancode, isrepeat)
  button = buttonMap[key]
  if button == nil then return end
  self:setButtonState(1, button, true)
end

function InputManager:onKeyReleased(key, scancode)
  button = buttonMap[key]
  if button == nil then return end
  self:setButtonState(1, button, false)
end

function InputManager:buttonUpdate(i, button)
  if self.p[i][button] > 0 then
    self.p[i][button] = self.p[i][button] + 1
  elseif self.p[i][button] < 0 then
    self.p[i][button] = self.p[i][button] - 1
  end
end

function InputManager:update(dt)
  for i = 1, 4 do
    for n, b in pairs(buttons) do
      self:buttonUpdate(i, b)
    end
  end
end

return InputManager
