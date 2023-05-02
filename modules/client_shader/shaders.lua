_G.ClientShaders = { }



--[[
Missing (maybe they are not needed):
- player:setWalkedDistance(...)
- onWalkEnd
- onAutoWalkEvent
]]

-- Fix for texture offset drawing, adding walking offsets.

--[[
local dirs = {
  [0] = {x = 0, y = 1},
  [1] = {x = 1, y = 0},
  [2] = {x = 0, y = -1},
  [3] = {x = -1, y = 0},
  [4] = {x = 1, y = 1},
  [5] = {x = 1, y = -1},
  [6] = {x = -1, y = -1},
  [7] = {x = -1, y = 1}
}

function onAutoWalkEvent() -- Not in use yet
  -- local player = g_game.getLocalPlayer()
end

function onWalkEvent() -- onWalkEnd callback and setWalkedDistance are missing in source
  local player = g_game.getLocalPlayer()
  local dir = g_game.getLastWalkDir()
  local w = player:getWalkedDistance()
  w.x = w.x + dirs[dir].x
  w.y = w.y + dirs[dir].y
  player:setWalkedDistance(w);
end
]]



function ClientShaders.init()
  -- Alias
  ClientShaders.m = modules.client_shader
end

function ClientShaders.terminate()
  _G.ClientShaders = nil
end



-- Kingdom Age

function ClientShaders.setMapShaderById(id)
  local shaderData = MapShaders[id]
  if not shaderData then
    return false
  end

  local map = GameInterface and GameInterface.getMapPanel()
  if not map then
    return false
  end

  map:setAntiAliasingMode(shaderData.antiAliasing or AntiAliasing.smoothRetro)
  map:setShader('Map - ' .. shaderData.name)

  map:setDrawViewportEdge(shaderData.drawViewportEdge == true)

  return true
end

function ClientShaders.setOutfitShaderById(creature, id)
  local shaderData = OutfitShaders[id]
  if not shaderData then
    return false
  end

  creature:setShader('Outfit - ' .. shaderData.name)
  creature:setDrawOutfitColor(shaderData.drawColor ~= false)

  return true
end

function ClientShaders.setMountShaderById(creature, id)
  local shaderData = MountShaders[id]
  if not shaderData then
    return false
  end

  creature:setMountShader('Mount - ' .. shaderData.name)

  return true
end

function ClientShaders.setItemShaderById(item, id)
  local shaderData = ItemShaders[id]
  if not shaderData then
    return false
  end

  item:setShader('Item - ' .. shaderData.name)

  return true
end
