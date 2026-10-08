_G.ClientShaders = { }

local textShadersByName = { }
textShadersByName.None = ''
for _, shaderData in ipairs(TextShaders) do
  local shaderName = shaderData.frag and shaderData.name or ''
  textShadersByName[shaderData.name] = shaderName
  textShadersByName[shaderData.name:gsub('^Outline %- ', '')] = shaderName
end

local function resolveTextShader(shaderName)
  if type(shaderName) == 'number' then
    local shaderData = TextShaders[shaderName]
    return shaderData and (shaderData.frag and shaderData.name or '') or nil
  end

  if shaderName == nil or shaderName == false or shaderName == '' or shaderName == 'None' then
    return ''
  end

  local shaderData = textShadersByName[shaderName]
  return type(shaderData) == 'string' and shaderData or shaderName
end

local function resolveWidgetTextShader(shaderName)
  local resolved = resolveTextShader(shaderName)
  if resolved == nil or resolved == '' then
    return resolved
  end

  if resolved:sub(1, 9) == 'Widget - ' then
    return resolved
  end

  if resolved:sub(1, 10) == 'Outline - ' then
    return 'Widget - ' .. resolved
  end

  return resolved
end

function ClientShaders.getTextShaderName(shaderName)
  return resolveTextShader(shaderName)
end

function ClientShaders.getWidgetTextShaderName(shaderName)
  return resolveWidgetTextShader(shaderName)
end

function ClientShaders.setCreatureNameShader(creature, shaderName)
  if not creature then
    return false
  end

  local resolved = resolveTextShader(shaderName)
  if resolved == nil then
    return false
  end

  -- Keep the generic shader on the creature even when information is drawn by
  -- a widget. This lets the widget be created after the server opcode arrives
  -- and still receive the selected shader.
  creature:setNameShader(resolved)

  local infoWidget = creature:getWidgetInformation()
  if infoWidget and infoWidget.name then
    local widgetShader = g_gameConfig.isDrawingInformationByWidget() and resolveWidgetTextShader(resolved) or ''
    infoWidget.name:setShader(widgetShader)
  end

  return true
end

function ClientShaders.setCreatureNameShaderById(creature, id)
  return ClientShaders.setCreatureNameShader(creature, id)
end

function ClientShaders.removeCreatureNameShader(creature)
  return ClientShaders.setCreatureNameShader(creature, nil)
end

function ClientShaders.setWidgetTextShader(widget, shaderName)
  if not widget then
    return false
  end

  local resolved = resolveWidgetTextShader(shaderName)
  if resolved == nil then
    return false
  end

  widget:setShader(resolved)
  return true
end

function ClientShaders.setWidgetTextShaderById(widget, id)
  return ClientShaders.setWidgetTextShader(widget, id)
end

function ClientShaders.removeWidgetTextShader(widget)
  return ClientShaders.setWidgetTextShader(widget, nil)
end



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

  connect(g_game, {
    onGameStart = ClientShaders.onGameStart,
  })

  ProtocolGame.registerOpcode(ServerOpcodes.ServerOpcodeMapShaders, ClientShaders.parse)
  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeCreatureNameShader, ClientShaders.parseCreatureNameShader)
end

function ClientShaders.terminate()
  ProtocolGame.unregisterOpcode(ServerOpcodes.ServerOpcodeMapShaders)
  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeCreatureNameShader)

  disconnect(g_game, {
    onGameStart = ClientShaders.onGameStart,
  })

  _G.ClientShaders = nil
  g_shaders.clear()
end



function ClientShaders.setMapShaderById(id)
  local shaderData = MapShaders[id]
  if not shaderData then
    return false
  end

  local map = GameInterface and GameInterface.getMapPanel()
  if not map then
    return false
  end

  -- Disable all filters
  for _, shaderData in ipairs(MapShaders) do
    if shaderData.onEnable then
      shaderData.onEnable(map, false) -- Disable shader
    end
  end
  -- Enable actual filter (if has a filter to be enabled)
  if shaderData.onEnable then
    shaderData.onEnable(map, true) -- Enable shader
  end

  map:setAntiAliasingMode(shaderData.antiAliasing or AntiAliasing.smoothRetro)
  map:setShader('Map - ' .. shaderData.name)

  map:setDrawViewportEdge(true) -- Needed for Heat, Pulse, Radial Blur and Zomg

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



-- Events

function ClientShaders.parse(protocol, msg)
  local coordEffects       = { }
  local coordEffectsAmount = msg:getU8()
  for i = 1, coordEffectsAmount do
    local id         = msg:getU32()
    local state      = msg:getU8() == 1
    coordEffects[id] = state
  end

  local effects       = { }
  local effectsAmount = msg:getU8()
  for i = 1, effectsAmount do
    local id    = msg:getU32()
    local state = msg:getU8() == 1
    effects[id] = state
  end

  local map = GameInterface and GameInterface.getMapPanel()
  if not map then
    return
  end

  -- Update coordEffects
  for id, state in pairs(coordEffects) do
    map:setDrawCoordEffectShaders(id, state)
  end

  -- Update effects
  for id, state in pairs(effects) do
    map:setDrawEffectShaders(id, state)
  end
end

function ClientShaders.parseCreatureNameShader(protocol, opcode, msg)
  local creature = g_map.getCreatureById(msg:getU32())
  local shaderName = msg:getString()
  if creature then
    ClientShaders.setCreatureNameShader(creature, shaderName)
  end
end

function ClientShaders.onGameStart()
  addEvent(function() ClientShaders.setMapShaderById(ClientOptions.getOption('shaderFilter')) end)
end
