local MapNode = {}
MapNode.__index = MapNode

function MapNode.new(x, y, edge)
  local mapnode = {x = x, y = y, edge = edge}
  setmetatable(mapnode, MapNode)
  return mapnode
end

function MapNode:getNeighbors()
  local neighbors = {}
  if not (self.right == nil) then table.insert(neighbors, self.right) end
  if not (self.down == nil) then table.insert(neighbors, self.down) end
  if not (self.left == nil) then table.insert(neighbors, self.left) end
  if not (self.up == nil) then table.insert(neighbors, self.up) end
  return neighbors
end

function MapNode:isOrphan()
  return self.edge == 0
end

function MapNode:isOneWay()
  -- Only one edge
  return self.edge == 1 or self.edge == 2 or self.edge == 4 or self.edge == 8
end

function MapNode:isTwoWay()
  -- Either straight edges, or corner edges.
  return self.edge == 5 or self.edge == 10 or self.edge == 3 or self.edge == 6 or self.edge == 9 or self.edge == 12
end

-- Edge testing functions. This is awkward without bitwise ops.
function MapNode:isRightEdge(edge)
  return self.edge % 2 >= 1
end

function MapNode:isDownEdge(edge)
  return self.edge % 4 >= 2
end

function MapNode:isLeftEdge(edge)
  return self.edge % 8 >= 4
end

function MapNode:isUpEdge(edge)
  return self.edge % 16 >= 8
end

local MapGraph = {}
MapGraph.__index = MapGraph

-- Converts a tile number to an edge, assuming
-- that graph tiles start on tile 32, and have
-- a pitch of 8.
function tileToEdge(tile)
  -- Move to zero based indexing.
  tile = tile - 1

  -- Move to graph tiles.
  tile = tile - 32

  -- Check row bounds
  if tile < 0 or tile >= 32 then return nil end

  -- Get coordinates.
  local row = math.floor(tile / 8)
  local col = tile % 8

  -- Check column bounds
  if col >= 4 then return nil end

  -- Convert coordinates to tile edges.
  return col + row * 4
end

local playerTiles = {17, 19, 25, 27}

function MapGraph.new(tilemap)
  mapgraph = {}
  setmetatable(mapgraph, MapGraph)
  mapgraph:init(tilemap)
  return mapgraph
end

function MapGraph:init(tilemap)
  self.nodemap = {}

  -- Build nodemap rows
  for y = 1, tilemap.height do
    self.nodemap[y] = {}
  end

  self.orphans = {}
  self.playerOrigins = {}

  for i, layer in pairs(tilemap.layers) do
    -- Initialize nodes.
    for y = 1, layer.height do
      for x = 1, layer.width do
        local tileindex = (y - 1) * layer.width + x
        local data = layer.data[tileindex]
        local edge = tileToEdge(data)
        if not (edge == nil) then
          self.nodemap[y][x] = MapNode.new(x, y, edge)
        end
        for player, tile in pairs(playerTiles) do
          if data == tile then
            self.playerOrigins[player] = {x = x, y = y}
          end
        end
      end
    end

    -- Connect nodes.
    for y = 1, layer.height do
      for x = 1, layer.width do
        local node = self.nodemap[y][x]
        if not (node == nil) then
          if node:isOrphan() then
            if node.edge > 0 then
              table.insert(self.orphans, node)
            end
          else
            if node:isRightEdge() then
              local neighbor = self.nodemap[y][x + 1]
              assert(not (neighbor == nil), "right edge is not connected to node")
              assert(neighbor:isLeftEdge(), "right edge not mutual at " .. x .. ", " .. y .. " (edge: " .. neighbor.edge .. ")")
              node.right = neighbor
            end

            if node:isDownEdge() then
              local neighbor = self.nodemap[y + 1][x]
              assert(not (neighbor == nil), "down edge is not connected to node")
              assert(neighbor:isUpEdge(), "down edge not mutual at " .. x .. ", " .. y .. " (edge: " .. neighbor.edge .. ")")
              node.down = neighbor
            end

            if node:isLeftEdge() then
              local neighbor = self.nodemap[y][x - 1]
              assert(not (neighbor == nil), "left edge is not connected to node")
              assert(neighbor:isRightEdge(), "left edge not mutual at " .. x .. ", " .. y .. " (edge: " .. neighbor.edge .. ")")
              node.left = neighbor
            end

            if node:isUpEdge() then
              local neighbor = self.nodemap[y - 1][x]
              assert(not (neighbor == nil), "up edge is not connected to node")
              assert(neighbor:isDownEdge(), "up edge not mutual at " .. x .. ", " .. y .. " (edge: " .. neighbor.edge .. ")")
              node.up = neighbor
            end
          end
        end
      end
    end
  end
end

function MapGraph:getNodeAt(coords)
  return self.nodemap[coords.y][coords.x]
end

-- Gets the jump node for an orphan if one exists.
-- This is the node the player jumps to off of an orphan node.
function MapGraph:getJumpNode(node)
  local jump = self.nodemap[node.y][node.x + 1]
  if not (jump == nil) then
    return jump
  end
  jump = self.nodemap[node.y + 1][node.x]
  if not (jump == nil) then
    return jump
  end
  jump = self.nodemap[node.y][node.x - 1]
  if not (jump == nil) then
    return jump
  end
  return self.nodemap[node.y - 1][node.x]
end

return MapGraph
