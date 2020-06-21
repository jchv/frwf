local input = {}
input.p = {}

for i = 1, 4 do
  input.p[i] = {}
  input.p[i].a = 0
  input.p[i].b = 0
  input.p[i].u = 0
  input.p[i].d = 0
  input.p[i].l = 0
  input.p[i].r = 0
end

function input.buttondown(i, button)
  if input.p[i][button] <= 0 then
    for i = 1, 4 do
      input.p[i][button] = 1
    end
  end
end

function input.buttonup(i, button)
  if input.p[i][button] >= 0 then
    for i = 1, 4 do
      input.p[i][button] = -1
    end
  end
end

function love.keypressed(key, scancode, isrepeat)
  if key == "f" then input.buttondown(1, "a") end
  if key == "g" then input.buttondown(1, "b") end
  if key == "w" then input.buttondown(1, "u") end
  if key == "s" then input.buttondown(1, "d") end
  if key == "a" then input.buttondown(1, "l") end
  if key == "d" then input.buttondown(1, "r") end
end

function love.keyreleased(key, scancode, isrepeat)
  if key == "f" then input.buttonup(1, "a") end
  if key == "g" then input.buttonup(1, "b") end
  if key == "w" then input.buttonup(1, "u") end
  if key == "s" then input.buttonup(1, "d") end
  if key == "a" then input.buttonup(1, "l") end
  if key == "d" then input.buttonup(1, "r") end
end

function input.buttonupdate(i, button)
  if input.p[i][button] > 0 then
    input.p[i][button] = input.p[i][button] + 1
  elseif input.p[i][button] < 0 then
    input.p[i][button] = input.p[i][button] - 1
  end
end

function input.update(dt)
  for i = 1, 4 do
    input.buttonupdate(i, "a")
    input.buttonupdate(i, "b")
    input.buttonupdate(i, "u")
    input.buttonupdate(i, "d")
    input.buttonupdate(i, "l")
    input.buttonupdate(i, "r")
  end
end

return input
