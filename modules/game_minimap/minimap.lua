_G.GameMinimap = { }



minimapWindow = nil
minimapTopMenuButton = nil
minimapWidget = nil

minimapBar = nil
minimapOpacityScrollbar = nil
positionLabel = nil

arrowMenuButton = nil
ballButton = nil
infoLabel = nil

otmm = true
preloaded = false
fullmapView = false
oldZoom = nil
oldPos = nil
instanceId = 0
instanceName = ""


local lastMinimapMarkId = 19

local function updatePositionLabel()
  local text

  -- Default map
  if instanceId < 1 then
    local player = g_game.getLocalPlayer()
    if not player then
      return
    end
    local pos = player:getPosition()
    if not pos then
      return
    end

    text = tr('%d, %d, %d', pos.x, pos.y, pos.z)

  -- Instance map
  else
    text = instanceName
  end

  positionLabel:setText(text)
  positionLabel:setTooltip(text)
end



function GameMinimap.init()
  -- Alias
  GameMinimap.m = modules.game_minimap

  minimapWindow        = g_ui.loadUI('minimap')
  local contentsPanel  = minimapWindow:getChildById('contentsPanel')
  minimapTopMenuButton = ClientTopMenu.addRightGameToggleButton('minimapTopMenuButton', tr('Minimap') .. ' (Ctrl+M)', '/images/ui/top_menu/minimap', GameMinimap.toggle)

  minimapWindow.topMenuButton = minimapTopMenuButton

  minimapWidget = contentsPanel:getChildById('minimap')

  minimapBar = contentsPanel:getChildById('minimapBar')
  minimapOpacityScrollbar = contentsPanel:getChildById('minimapOpacity')
  minimapOpacityScrollbar:setValue(g_settings.getValue('Minimap', 'opacity', 100))
  positionLabel = contentsPanel:getChildById('positionLabel')

  arrowMenuButton = minimapWindow:getChildById('arrowMenuButton')
  ballButton = minimapWindow:getChildById('ballButton')
  infoLabel = minimapWindow:getChildById('emptyMenuButton')

  for i = 1, lastMinimapMarkId do
    g_textures.preload(string.format('/images/ui/minimap/flag%d', i))
  end

  local gameRootPanel = GameInterface.getRootPanel()
  g_keyboard.bindKeyPress('Alt+Left', function() minimapWidget:move(1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Right', function() minimapWidget:move(-1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Up', function() minimapWidget:move(0,1) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Down', function() minimapWidget:move(0,-1) end, gameRootPanel)
  g_keyboard.bindKeyDown('Ctrl+M', GameMinimap.toggle)
  g_keyboard.bindKeyDown('Ctrl+Shift+M', GameMinimap.toggleFullMap)
  g_keyboard.bindKeyDown('Escape', function() if fullmapView then GameMinimap.toggleFullMap() end end)

  ProtocolGame.registerExtendedOpcode(GameServerExtOpcodes.GameServerInstanceInfo, GameMinimap.onInstanceInfo)

  connect(g_game, {
    onGameStart = GameMinimap.online,
    onGameEnd   = GameMinimap.offline
  })

  connect(LocalPlayer, {
    onPositionChange = GameMinimap.updateCameraPosition
  })

  GameInterface.setupMiniWindow(minimapWindow, minimapTopMenuButton)

  if g_game.isOnline() then
    GameMinimap.online()
  end
end

function GameMinimap.terminate()
  if g_game.isOnline() then
    GameMinimap.saveMap()
  end

  if fullmapView then
    GameMinimap.toggleFullMap()
  end

  g_settings.setValue('Minimap', 'opacity', minimapOpacityScrollbar:getValue())

  disconnect(g_game, {
    onGameStart = GameMinimap.online,
    onGameEnd   = GameMinimap.offline
  })

  disconnect(LocalPlayer, {
    onPositionChange = GameMinimap.updateCameraPosition
  })

  ProtocolGame.unregisterExtendedOpcode(GameServerExtOpcodes.GameServerInstanceInfo)

  local gameRootPanel = GameInterface.getRootPanel()
  g_keyboard.unbindKeyPress('Alt+Left', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Right', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Up', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Down', gameRootPanel)
  g_keyboard.unbindKeyDown('Ctrl+M')
  g_keyboard.unbindKeyDown('Ctrl+Shift+M')
  g_keyboard.unbindKeyDown('Escape')

  minimapWindow:destroy()
  minimapTopMenuButton:destroy()

  _G.GameMinimap = nil
end

function GameMinimap.toggle()
  if fullmapView then
    GameMinimap.toggleFullMap()
  end
  GameInterface.toggleMiniWindow(minimapWindow)
end

function GameMinimap.preload()
  GameMinimap.loadMap(false)
  preloaded = true
end

function GameMinimap.online()
  GameInterface.setupMiniWindow(minimapWindow, minimapTopMenuButton)

  GameMinimap.loadMap(not preloaded)

  instanceId   = 0
  instanceName = ""
  GameMinimap.updateCameraPosition()

  minimapWidget:setOpacity(1.0)
end

function GameMinimap.offline()
  GameMinimap.saveMap()
  if fullmapView then
    GameMinimap.toggleFullMap()
  end
end

function GameMinimap.loadMap(clean)
  local clientVersion = g_game.getClientVersion()

  if clean then
    g_minimap.clean()
  end

  if otmm then
    local minimapFile = '/minimap.otmm'
    if g_resources.fileExists(minimapFile) then
      g_minimap.loadOtmm(minimapFile)
    end
  else
    local minimapFile = '/minimap_' .. clientVersion .. '.otcm'
    if g_resources.fileExists(minimapFile) then
      g_map.loadOtcm(minimapFile)
    end
  end
  minimapWidget:load()
end

function GameMinimap.saveMap()
  local clientVersion = g_game.getClientVersion()
  if otmm then
    local minimapFile = '/minimap.otmm'
    g_minimap.saveOtmm(minimapFile)
  else
    local minimapFile = '/minimap_' .. clientVersion .. '.otcm'
    g_map.saveOtcm(minimapFile)
  end
  minimapWidget:save()
end

function GameMinimap.updateCameraPosition()
  local player = g_game.getLocalPlayer()
  if not player then
    return
  end
  local pos = player:getPosition()
  if not pos then
    return
  end

  if instanceId < 1 then
    local text = tr('%d, %d, %d', pos.x, pos.y, pos.z)

    positionLabel:setText(text)
    positionLabel:setTooltip(text)
  end

  if not minimapWidget:isDragging() then
    if not fullmapView then
      minimapWidget:setCameraPosition(player:getPosition())
    end
    minimapWidget:setCrossPosition(player:getPosition())
  end
end

function GameMinimap.toggleFullMap()
  -- Try to open fullscreen without minimap being opened
  if not fullmapView and not minimapWindow:isVisible() then
    return
  end

  fullmapView = not fullmapView

  -- Update parent

  local rootPanel = GameInterface.getRootPanel()
  local parent    = fullmapView and rootPanel or minimapWindow:getChildById('contentsPanel')

  minimapWidget:setParent(parent)
  minimapBar:setParent(parent)
  positionLabel:setParent(parent)
  minimapOpacityScrollbar:setParent(parent)

  arrowMenuButton:setParent(fullmapView and rootPanel or minimapWindow)
  ballButton:setParent(fullmapView and rootPanel or minimapWindow)
  infoLabel:setParent(fullmapView and rootPanel or minimapWindow)

  -- Update anchors and others

  positionLabel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  positionLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  positionLabel:addAnchor(AnchorRight, 'minimapBar', AnchorLeft)
  minimapOpacityScrollbar:addAnchor(AnchorBottom, 'positionLabel', AnchorOutsideTop)
  minimapOpacityScrollbar:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  minimapOpacityScrollbar:addAnchor(AnchorRight, 'minimapBar', AnchorOutsideLeft)
  minimapOpacityScrollbar:setVisible(fullmapView)

  if fullmapView then
    minimapWindow:hide()
    minimapWidget:fill('parent')
    minimapWidget:setAlternativeWidgetsVisible(true)
    minimapWidget:setOpacity(minimapOpacityScrollbar:getValue() / 100)

    minimapBar:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    minimapBar:addAnchor(AnchorRight, 'parent', AnchorRight)

    arrowMenuButton:addAnchor(AnchorTop, 'minimapBar', AnchorTop)
    arrowMenuButton:addAnchor(AnchorRight, 'minimapBar', AnchorOutsideLeft)
    arrowMenuButton:setTooltip(tr('Hide entire game map (%s)', 'Ctrl+Shift+M'))
    arrowMenuButton:setOn(true)
    ballButton:addAnchor(AnchorTop, 'prev', AnchorBottom)
    ballButton:addAnchor(AnchorRight, 'minimapBar', AnchorLeft)
    ballButton:setMarginTop(3)
    infoLabel:addAnchor(AnchorTop, 'prev', AnchorBottom)
    infoLabel:addAnchor(AnchorRight, 'minimapBar', AnchorLeft)
    infoLabel:setMarginTop(3)
  else
    minimapWindow:show()
    minimapWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
    minimapWidget:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    minimapWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    minimapWidget:addAnchor(AnchorRight, 'minimapBar', AnchorLeft)
    minimapWidget:setAlternativeWidgetsVisible(false)
    minimapWidget:setOpacity(1.0)

    minimapBar:addAnchor(AnchorTop, 'parent', AnchorTop)
    minimapBar:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    minimapBar:addAnchor(AnchorRight, 'parent', AnchorRight)

    arrowMenuButton:addAnchor(AnchorVerticalCenter, 'lockButton', AnchorVerticalCenter)
    arrowMenuButton:addAnchor(AnchorRight, 'lockButton', AnchorOutsideLeft)
    arrowMenuButton:setTooltip(tr('Show entire game map (%s)', 'Ctrl+Shift+M'))
    arrowMenuButton:setOn(false)
    ballButton:addAnchor(AnchorTop, 'prev', AnchorTop)
    ballButton:addAnchor(AnchorRight, 'prev', AnchorLeft)
    ballButton:setMarginTop(0)
    infoLabel:addAnchor(AnchorTop, 'prev', AnchorTop)
    infoLabel:addAnchor(AnchorRight, 'prev', AnchorLeft)
    infoLabel:setMarginTop(0)
  end

  -- Update zoom

  local zoom = oldZoom or 0
  oldZoom    = minimapWidget:getZoom()
  minimapWidget:setZoom(zoom)

  -- Update camera position

  GameMinimap.updateCameraPosition()
end

function GameMinimap.getMinimapWidget()
  return minimapWidget
end

function GameMinimap.getMinimapBar()
  return minimapBar
end

function GameMinimap.onInstanceInfo(protocol, opcode, buffer)
  local params = string.split(buffer, ':')

  local id, name
  if #params == 2 then
    id   = tonumber(params[1])
    name = params[2]
  else
    id   = 0
    name = ""
  end

  if id < 1 or not name then
    name = ""
  end

  instanceId   = id
  instanceName = name

  updatePositionLabel()
end
