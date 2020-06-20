function love.load()
    splash = love.graphics.newImage("splash.png")
    love.window.setMode(320, 288, {resizable=false, vsync=true})
    love.graphics.setDefaultFilter("nearest", "nearest", 0)
    canvas = love.graphics.newCanvas(160, 144)
end

local t = 0
function love.update(dt)
    t = t + dt
end

function math.round(n, deci)
    deci = 10^(deci or 0)
    return math.floor(n*deci+.5)/deci
end

function love.draw()
    love.graphics.setColor(1, 1, 1, 1)
    if t < 4 then
        love.graphics.clear(1, 1, 1)
        love.graphics.draw(splash, 0, math.round(t * 72 - 288, 2))
    elseif t < 5 then
        love.graphics.clear(1, 1, 1)
        love.graphics.draw(splash, 0, 0)
    elseif t < 6 then
        love.graphics.clear(1, 1, 1)
        love.graphics.setColor(1, 1, 1, math.round((6 - t) * 8) / 8)
        love.graphics.draw(splash, 0, 0)
    elseif t < 7 then
        love.graphics.clear(1, 1, 1)
    elseif t < 8 then
        local v = math.round((8 - t) * 8) / 8
        love.graphics.clear(v, v, v)
    else
        love.graphics.setCanvas(canvas)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.clear()
            love.graphics.setBlendMode("alpha")
            love.graphics.print("Hello World", 10 + math.sin(t) * 10, 10)
        love.graphics.setCanvas()

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(canvas, 0, 0, 0, 2)
    end
end