local TileSet = {}
TileSet.__index = TileSet

function TileSet.new(tileset, tilew, tileh)
  local tileset = {
      tilew = tilew,
      tileh = tileh,
      img = love.graphics.newImage(tileset),
      quads = {},
  }
  setmetatable(tileset, TileSet)

  local imgw = tileset.img:getWidth()
  local imgh = tileset.img:getHeight()
  local cols = imgw / tilew
  local rows = imgh / tileh
  local i = 1

  for ty = 0, rows - 1 do
    for tx = 0, cols - 1 do
      tileset.quads[i] = love.graphics.newQuad(tx * tilew, ty * tileh, tilew, tileh, imgw, imgh)
      i = i + 1
    end
  end

  return tileset
end

function TileSet:drawTile(x, y, tile)
  love.graphics.draw(self.img, self.quads[tile], x, y)
end

function TileSet:drawTileLayer(layer, dx, dy)
  for y = 0, layer.height - 1 do
    for x = 0, layer.width - 1 do
      local tile = layer.data[y * layer.width + x + 1]
      if tile > 0 then
        self:drawTile(x * self.tilew + dx, y * self.tileh + dy, tile)
      end
    end
  end
end

function TileSet:drawMap(tilemap, dx, dy)
  for i, layer in pairs(tilemap.layers) do
    if layer.visible == true and layer.type == "tilelayer" then
      self:drawTileLayer(layer, dx, dy)
    end
  end
end

-- Returns the map position of the center of a given tile using this tileset's
-- metrics.
function TileSet:tilePos(tileCoords)
  return {
    x = (tileCoords.x - 1) * self.tilew + self.tilew / 2,
    y = (tileCoords.y - 1) * self.tileh + self.tileh / 2,
  }
end

return TileSet
