_G.GameMinimap = { }

MinimapFlags = {
  Info = 1,
  View = 2,
}

minimapWindow = nil
minimapTopMenuButton = nil
minimapBackgroundWidget = nil
minimapWidget = nil

minimapBar = nil
minimapOpacityScrollbar = nil
positionLabel = nil

ballButton = nil
infoLabel = nil

extraIconsButton = nil
fullMapButton = nil

preloaded = false
oldPos = nil

currentMapFilename = ''

local lastMinimapMarkId = 19



function GameMinimap.init()
  -- Alias
  GameMinimap.m = modules.game_minimap

  minimapWindow        = g_ui.loadUI('minimap')
  local contentsPanel  = minimapWindow:getChildById('contentsPanel')
  minimapTopMenuButton = ClientTopMenu.addRightGameToggleButton('minimapTopMenuButton', tr('Minimap') .. ' (Ctrl+M)', '/images/ui/top_menu/minimap', GameMinimap.toggle)

  minimapWindow.topMenuButton = minimapTopMenuButton

  minimapBackgroundWidget = contentsPanel:getChildById('background')
  minimapBackgroundWidget:hide()

  minimapWidget = contentsPanel:getChildById('minimap')

  minimapBar = contentsPanel:getChildById('minimapBar')
  minimapOpacityScrollbar = contentsPanel:getChildById('minimapOpacity')
  minimapOpacityScrollbar:setValue(g_settings.getValue('Minimap', 'opacity', 100))
  positionLabel = contentsPanel:getChildById('positionLabel')

  ballButton = minimapWindow:getChildById('ballButton')
  infoLabel = minimapWindow:getChildById('infoButton')

  local compassWidget = minimapBar:getChildById('compass')
  extraIconsButton = compassWidget:getChildById('extraIconsButton')
  fullMapButton = compassWidget:getChildById('fullMapButton')

  for i = 1, lastMinimapMarkId do
    g_textures.preload(f('/images/ui/minimap/flag%d', i))
  end

  local gameRootPanel = GameInterface.getRootPanel()
  g_keyboard.bindKeyPress('Alt+Left', function() minimapWidget:move(1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Right', function() minimapWidget:move(-1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Up', function() minimapWidget:move(0,1) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Down', function() minimapWidget:move(0,-1) end, gameRootPanel)
  g_keyboard.bindKeyDown('Ctrl+M', GameMinimap.toggle)
  g_keyboard.bindKeyDown('Ctrl+Shift+M', GameMinimap.toggleFullMap)
  g_keyboard.bindKeyDown('Escape', function() if minimapWidget.fullMapView then GameMinimap.toggleFullMap() end end)

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeInstanceInfo, GameMinimap.onInstanceInfo)

  connect(g_game, {
    onGameStart        = GameMinimap.online,
    onGameEnd          = GameMinimap.offline,
    onTrackPosition    = GameMinimap.onTrackPosition,
    onTrackPositionEnd = GameMinimap.onTrackPositionEnd,
    onUpdateTrackColor = GameMinimap.onUpdateTrackColor
  })

  connect(LocalPlayer, {
    onPositionChange = GameMinimap.updateCameraPosition
  })

  if g_game.isOnline() then
    GameMinimap.online()
  end
end

function GameMinimap.terminate()
  if g_game.isOnline() then
    GameMinimap.saveMap()
  end

  if minimapWidget.fullMapView then
    GameMinimap.toggleFullMap()
  end

  g_settings.setValue('Minimap', 'opacity', minimapOpacityScrollbar:getValue())

  disconnect(LocalPlayer, {
    onPositionChange = GameMinimap.updateCameraPosition
  })

  disconnect(g_game, {
    onGameStart        = GameMinimap.online,
    onGameEnd          = GameMinimap.offline,
    onTrackPosition    = GameMinimap.onTrackPosition,
    onTrackPositionEnd = GameMinimap.onTrackPositionEnd,
    onUpdateTrackColor = GameMinimap.onUpdateTrackColor
  })

  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeInstanceInfo)

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
  if minimapWidget.fullMapView then
    GameMinimap.toggleFullMap()
  end
  GameInterface.toggleMiniWindow(minimapWindow)
end

function GameMinimap.preload()
  GameMinimap.loadMap(false)
  preloaded = true
end

function GameMinimap.online()
  minimapWindow:setup(minimapTopMenuButton)

  GameMinimap.loadMap(not preloaded)
  GameMinimap.updateCameraPosition()

  minimapWidget:setOpacity(1.0)
end

function GameMinimap.offline()
  GameMinimap.saveMap()
  if minimapWidget.fullMapView then
    GameMinimap.toggleFullMap()
  end
  currentMapFilename = ''
end

function GameMinimap.loadMap(clean)
  if clean then
    g_minimap.clean()
  end

  local minimapFile = '/minimap.otmm'
  if string.exists(currentMapFilename) then
    minimapFile = tr('/%s.otmm', currentMapFilename)
    preloaded = false
  end

  if g_resources.fileExists(minimapFile) then
    g_minimap.loadOtmm(minimapFile)
  end
  minimapWidget:load()
end

function GameMinimap.saveMap()
  local minimapFile = '/minimap.otmm'
  if string.exists(currentMapFilename) then
    minimapFile = tr('/%s.otmm', currentMapFilename)
  end

  g_minimap.saveOtmm(minimapFile)
  minimapWidget:save()
end

function GameMinimap.updateCameraPosition()
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then
    return
  end

  local pos = localPlayer:getPosition()
  if not pos then
    return
  end

  if localPlayer:getInstanceId() < 1 then
    local text = f('%d, %d, %d', pos.x, pos.y, pos.z)

    positionLabel:setText(text)
    positionLabel:setTooltip(text)
  end

  if not minimapWidget:isDragging() then
    if not minimapWidget.fullMapView then
      minimapWidget:setCameraPosition(localPlayer:getPosition())
    end
    minimapWidget:setCrossPosition(localPlayer:getPosition())
  end
end

function GameMinimap.toggleFullMap()
  -- Try to open fullscreen without minimap being opened
  if not minimapWidget.fullMapView and not minimapWindow:isVisible() then
    return
  end

  minimapWidget.fullMapView = not minimapWidget.fullMapView

  -- Update parent

  local rootPanel = GameInterface.getRootPanel()
  local parent    = minimapWidget.fullMapView and rootPanel or minimapWindow:getChildById('contentsPanel')

  minimapBackgroundWidget:setParent(parent)
  minimapWidget:setParent(parent)
  minimapBar:setParent(parent)
  positionLabel:setParent(parent)
  minimapOpacityScrollbar:setParent(parent)

  ballButton:setParent(minimapWidget.fullMapView and rootPanel or minimapWindow)
  infoLabel:setParent(minimapWidget.fullMapView and rootPanel or minimapWindow)

  -- Update anchors and others

  minimapBar:addAnchor(AnchorTop, 'parent', AnchorTop)
  minimapBar:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  minimapBar:addAnchor(AnchorRight, 'parent', AnchorRight)
  positionLabel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  positionLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  positionLabel:addAnchor(AnchorRight, 'minimapBar', AnchorOutsideLeft)
  minimapOpacityScrollbar:addAnchor(AnchorBottom, 'positionLabel', AnchorOutsideTop)
  minimapOpacityScrollbar:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  minimapOpacityScrollbar:addAnchor(AnchorRight, 'minimapBar', AnchorOutsideLeft)
  minimapOpacityScrollbar:setVisible(minimapWidget.fullMapView)

  if minimapWidget.fullMapView then
    local opacity = minimapOpacityScrollbar:getValue() / 100

    minimapWindow:hide()
    minimapBackgroundWidget:fill('parent')
    minimapBackgroundWidget:setOpacity(opacity)
    minimapWidget:fill('parent')
    minimapWidget:setOpacity(opacity)

    fullMapButton:setOn(true)
    ballButton:addAnchor(AnchorTop, 'minimapBar', AnchorTop)
    ballButton:addAnchor(AnchorRight, 'minimapBar', AnchorOutsideLeft)
    infoLabel:addAnchor(AnchorTop, 'prev', AnchorBottom)
    infoLabel:addAnchor(AnchorRight, 'minimapBar', AnchorOutsideLeft)
    infoLabel:setMarginTop(3)

    minimapWidget:setZoom(minimapWidget.zoomFullmap)
  else
    minimapWindow:show()
    minimapBackgroundWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
    minimapBackgroundWidget:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    minimapBackgroundWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    minimapBackgroundWidget:addAnchor(AnchorRight, 'minimapBar', AnchorOutsideLeft)
    minimapBackgroundWidget:setOpacity(1.0)
    minimapWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
    minimapWidget:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    minimapWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    minimapWidget:addAnchor(AnchorRight, 'minimapBar', AnchorOutsideLeft)
    minimapWidget:setOpacity(1.0)

    fullMapButton:setOn(false)
    ballButton:addAnchor(AnchorVerticalCenter, 'lockButton', AnchorVerticalCenter)
    ballButton:addAnchor(AnchorRight, 'lockButton', AnchorOutsideLeft)
    infoLabel:addAnchor(AnchorVerticalCenter, 'prev', AnchorVerticalCenter)
    infoLabel:addAnchor(AnchorRight, 'prev', AnchorOutsideLeft)
    infoLabel:setMarginTop(0)

    minimapWidget:setZoom(minimapWidget.zoomMinimap)
  end

  -- Update camera position

  GameMinimap.updateCameraPosition()
end

function GameMinimap.getMinimapBackgroundWidget()
  return minimapBackgroundWidget
end

function GameMinimap.getMinimapWidget()
  return minimapWidget
end

function GameMinimap.getMinimapBar()
  return minimapBar
end

function GameMinimap.onInstanceInfo(protocolGame, opcode, msg)
  local flag = msg:getU8()

  -- Minimap info
  if flag == MinimapFlags.Info then
    local instanceId   = msg:getU32()
    local instancePath = msg:getString()
    local instanceName = msg:getString()

    local localPlayer  = g_game.getLocalPlayer()
    if not localPlayer then
      return
    end

    localPlayer:setInstanceId(instanceId)
    localPlayer:setInstanceName(instanceName)

    local formattedPath    = ''
    local minimapLabelText = ''

    -- Instance map
    if instanceId > 0 then
      formattedPath    = instancePath:gsub('.otbm', ''):gsub('/', '  '):gsub('%p', '_'):gsub('  ', '-'):gsub('%s','_'):lower()
      minimapLabelText = instanceName

    -- Default map
    else
      local pos = localPlayer:getPosition()
      if pos then
        minimapLabelText = f('%d, %d, %d', pos.x, pos.y, pos.z)
      end
    end

    positionLabel:setText(minimapLabelText)
    positionLabel:setTooltip(minimapLabelText)

    if formattedPath ~= currentMapFilename then
      GameMinimap.saveMap()
      currentMapFilename = formattedPath
      GameMinimap.loadMap(true)
    end

  -- View state
  elseif flag == MinimapFlags.View then
    local state = msg:getU8() == 1

    minimapBackgroundWidget:setVisible(not state)
    if state then
      minimapBackgroundWidget:removeTooltip()
    else
      minimapBackgroundWidget:setTooltip('Minimap not available')
    end

    minimapWidget:setVisible(state)
  end
end

function GameMinimap.onTrackPosition(posNode)
  if not posNode.minimapWidget then
    posNode.minimapWidget = g_ui.createWidget('TrackPin', minimapWidget)
    posNode.minimapWidget:setIconColor(posNode.color)
    posNode.minimapWidget.info = posNode
    posNode.minimapWidget.onMouseRelease = GameMinimap.createTrackMenu
    minimapWidget:centerInPosition(posNode.minimapWidget, posNode.position)
  end
end

function GameMinimap.onTrackPositionEnd(posNode)
  if posNode.minimapWidget then
    posNode.minimapWidget:destroy()
    posNode.minimapWidget = nil
  end
end

function GameMinimap.createTrackMenu(widget, mousePos, mouseButton)
  if mouseButton == MouseRightButton then
    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)
    if not widget.info.auto then
      menu:addOption(tr('Edit track'), function() GameTracker.createEditTrackWindow(widget.info) end)
      menu:addOption(tr('Stop track'), function() GameTracker.stopTrackPosition(widget.info.position) end)
    end
    menu:display(mousePos)
    return true
  end
  return false
end

function GameMinimap.onUpdateTrackColor(posNode)
  if posNode.minimapWidget then
    posNode.minimapWidget:setIconColor(posNode.color)
  end
end
