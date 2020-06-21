map = {}

function map.loadtiles(tileset, tilew, tileh)
  local set = {}
  set.tilew = tilew
  set.tileh = tileh
  set.img = love.graphics.newImage(tileset)
  set.quads = {}

  local imgw = set.img:getWidth()
  local imgh = set.img:getHeight()
  local tilel = imgw / tilew
  local tilev = imgh / tileh
  local i = 1

  for ty = 0, tilev - 1 do
    for tx = 0, tilel - 1 do
      set.quads[i] = love.graphics.newQuad(tx * tilew, ty * tileh, tilew, tileh, imgw, imgh)
      i = i + 1
    end
  end

  return set
end

function map.drawtile(tileset, x, y, tile)
  love.graphics.draw(tileset.img, tileset.quads[tile], x, y)
end

function map.drawtilelayer(layer, tileset, dx, dy)
  for y = 0, layer.height - 1 do
    for x = 0, layer.width - 1 do
      local tile = layer.data[y * layer.width + x + 1]
      if tile > 0 then
        map.drawtile(tileset, x * tileset.tilew + dx, y * tileset.tileh + dy, tile)
      end
    end
  end
end

function map.drawmap(tilemap, tileset, dx, dy)
  for i, layer in pairs(tilemap.layers) do
    if layer.visible == true and layer.type == "tilelayer" then
      map.drawtilelayer(layer, tileset, dx, dy)
    end
  end
end

function map.tilepos(tileset, tileCoords)
  return {
    x = (tileCoords.x - 1) * tileset.tilew + tileset.tilew / 2,
    y = (tileCoords.y - 1) * tileset.tileh + tileset.tileh / 2,
  }
end

return map
