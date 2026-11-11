local regionLabels = {
  { pos = { x = 3400, y = 2670, z = 7 }, text = loc'${GamelibInfoRegionRookieIsland}' },
  { pos = { x = 2743, y = 2721, z = 7 }, text = loc'${GamelibInfoRegionCityErembor}' },
  { pos = { x = 3017, y = 2619, z = 7 }, text = loc'${GamelibInfoRegionCityElensar}' },
  { pos = { x = 3224, y = 2687, z = 7 }, text = loc'${GamelibInfoRegionCityNova}' },
  { pos = { x = 2983, y = 2543, z = 7 }, text = loc'${GamelibInfoRegionCityNalta}' },
  { pos = { x = 3292, y = 2997, z = 7 }, text = loc'${GamelibInfoRegionCityDronMa}' },
  { pos = { x = 2655, y = 2597, z = 7 }, text = loc'${GamelibInfoRegionAmazoniaHideout}' },
  { pos = { x = 2710, y = 2580, z = 7 }, text = loc'${GamelibInfoRegionVengeanceVillage}' },
  { pos = { x = 2885, y = 2635, z = 7 }, text = loc'${GamelibInfoRegionMountFarber}' },
  { pos = { x = 2855, y = 2700, z = 7 }, text = loc'${GamelibInfoRegionEraninWoods}' },
  { pos = { x = 2740, y = 2795, z = 7 }, text = loc'${GamelibInfoRegionTrollShaws}' },
  { pos = { x = 2625, y = 2805, z = 7 }, text = loc'${GamelibInfoRegionDeathClawMountain}' },
  { pos = { x = 3155, y = 2595, z = 7 }, text = loc'${GamelibInfoRegionKrogHar}' },
  { pos = { x = 3133, y = 2713, z = 7 }, text = loc'${GamelibInfoRegionSandHills}' },
  { pos = { x = 2965, y = 2790, z = 7 }, text = loc'${GamelibInfoRegionMountChrist}' },
  { pos = { x = 3165, y = 2790, z = 7 }, text = loc'${GamelibInfoRegionMavigicValley}' },
  { pos = { x = 3140, y = 2855, z = 7 }, text = loc'${GamelibInfoRegionMavigicForest}' },
  { pos = { x = 3232, y = 2853, z = 7 }, text = loc'${GamelibInfoRegionMavigicCitadel}' },
  { pos = { x = 2992, y = 2867, z = 7 }, text = loc'${GamelibInfoRegionAnvhiansMines}' },
  { pos = { x = 2830, y = 2865, z = 7 }, text = loc'${GamelibInfoRegionHolkaganDesert}' },
  { pos = { x = 3077, y = 2920, z = 7 }, text = loc'${GamelibInfoRegionCyclopsTunnel}' },
  { pos = { x = 3100, y = 2990, z = 7 }, text = loc'${GamelibInfoRegionElvenCamp}' },
  { pos = { x = 3280, y = 2882, z = 7 }, text = loc'${GamelibInfoRegionLollaardCave}' },
  { pos = { x = 3000, y = 3052, z = 7 }, text = loc'${GamelibInfoRegionTempleAcegordsPlains}' },
  { pos = { x = 3000, y = 3120, z = 7 }, text = loc'${GamelibInfoRegionAcegordsPlains}' },
  { pos = { x = 3105, y = 3120, z = 7 }, text = loc'${GamelibInfoRegionDragonLair}' },
  { pos = { x = 3180, y = 3120, z = 7 }, text = loc'${GamelibInfoRegionVampireMansion}' },
  { pos = { x = 2875, y = 2975, z = 7 }, text = loc'${GamelibInfoRegionRakkarHills}' },
  { pos = { x = 2733, y = 3028, z = 7 }, text = loc'${GamelibInfoRegionGreenest}' },
  { pos = { x = 2690, y = 3080, z = 7 }, text = loc'${GamelibInfoRegionLusorSwamp}' },
  { pos = { x = 2495, y = 3120, z = 7 }, text = loc'${GamelibInfoRegionThartov}' },
  { pos = { x = 2865, y = 3135, z = 7 }, text = loc'${GamelibInfoRegionOutlawVillage}' },
  { pos = { x = 2790, y = 3240, z = 7 }, text = loc'${GamelibInfoRegionWealthIsland}' },
  { pos = { x = 2945, y = 3430, z = 7 }, text = loc'${GamelibInfoRegionRoshamuul}' },
}

local MinimapCreatureMarkerZoom = 0
local MinimapCreatureMarkerFullscreenZoom = 2
local MinimapPartyMarkerColor = '#3264c8'
local MinimapMonsterMarkerColor = '#ff4444'
local MinimapNpcMarkerColor = '#9f9dfd'

local function getCreatureMarkerMinimumZoom(minimap)
  return minimap.fullMapView and MinimapCreatureMarkerFullscreenZoom or MinimapCreatureMarkerZoom
end

local function bindCopyPositionOption(menu, pos)
  menu:addOption(loc'${GamelibInfoOptionCopyPosition}', function() g_window.setClipboardText(f(loc'${GamelibInfoPosition}', pos.x, pos.y, pos.z)) end)
end

local function findClosestCreatureMarker(markerTable, pos, extraIcons, closestMarker, closestDistance)
  for _, marker in pairs(markerTable) do
    local markerWidget
    if extraIcons then
      markerWidget = marker:getChildById('creatureWidget')
    else
      markerWidget = marker:getChildById('markerDot')
    end

    if marker:isVisible() and markerWidget:isVisible() and markerWidget:containsPoint(pos) then
      local center = markerWidget:getCenter()
      local dx = pos.x - center.x
      local dy = pos.y - center.y
      local distance = dx * dx + dy * dy
      if not closestDistance or distance < closestDistance then
        closestMarker = marker
        closestDistance = distance
      end
    end
  end

  return closestMarker, closestDistance
end

function UIMinimap:onCreate()
  self.autowalk = true
end

function UIMinimap:onSetup()
  self.addFlagWindow = nil
  self.editFlagWindow = nil
  self.floorUpWidget = self:getChildById('floorUp')
  self.floorDownWidget = self:getChildById('floorDown')
  self.zoomInWidget = self:getChildById('zoomIn')
  self.zoomOutWidget = self:getChildById('zoomOut')
  self.flags = { }
  self.fullMapView = false
  self.zoomMinimap = 0
  self.zoomFullmap = 0
  self.alternatives = { }
  self.alternativesVisible = true
  self.creatureMarkers = { }
  self.worldCreatureMarkers = { }
  self.creatureMarkersExtraIcons = true
  self.isMinimapHovered = false
  self.hoveredCreatureMarker = nil
  self.lastMousePos = nil
  self.onAddAutomapFlag = function(pos, icon, description, force, temporary)
    self:addFlag(pos, icon, description, force, temporary)
  end
  self.onRemoveAutomapFlag = function(pos)
    self:removeFlag(pos)
  end
  self.onGameEnd = function()
    for k = #self.flags, 1, -1 do
      local flag = self.flags[k]
      if flag.temporary then
        flag:destroy() -- Removed from list with onDestroy
      end
    end

    for _, widget in pairs(self.alternatives) do
      if widget.temporary then
        widget:destroy() -- Removed from list with onDestroy
      end
    end

    self:clearCreatureMarkers()
    self:clearWorldCreatureMarkers()
  end

  connect(g_game, {
    onAddAutomapFlag    = self.onAddAutomapFlag,
    onRemoveAutomapFlag = self.onRemoveAutomapFlag,
    onGameEnd           = self.onGameEnd,
  })

  -- Add title labels
  for _, regionLabel in ipairs(regionLabels) do
    local regionLabelWidget         = g_ui.createWidget('MinimapRegionLabel')
    regionLabelWidget.alternativeId = #self.alternatives + 1 -- ignoring creature minimap widgets
    regionLabelWidget.keepVisibleWhenAlternativesHidden = true
    regionLabelWidget.pos           = regionLabel.pos
    regionLabelWidget:setText(regionLabel.text)

    self:addAlternativeWidget(regionLabelWidget)
    self:centerInPosition(regionLabelWidget, regionLabelWidget.pos)
  end
end

function UIMinimap:onDestroy()
  self:clearCreatureMarkers()
  self:clearWorldCreatureMarkers()

  for _, widget in pairs(self.alternatives) do
    widget:destroy()
  end

  self.alternatives = { }

  disconnect(g_game, {
    onAddAutomapFlag    = self.onAddAutomapFlag,
    onRemoveAutomapFlag = self.onRemoveAutomapFlag,
    onGameEnd           = self.onGameEnd,
  })

  self:destroyAddFlagWindow()
  self:destroyEditFlagWindow()
  self.flags = { }
end

function UIMinimap:save()
  local settings = { flags = { } }

  for _, flag in pairs(self.flags) do
    if not flag.temporary then
      table.insert(settings.flags, {
        position = flag.pos,
        icon = flag.icon,
        description = flag.description,
      })
    end
  end

  settings.zoom     = self.zoomMinimap
  settings.zoomFull = self.zoomFullmap

  g_settings.setNode('Minimap', settings)
end

function UIMinimap:load()
  local settings = g_settings.getNode('Minimap')
  if settings then
    if settings.flags then
      for _, flag in pairs(settings.flags) do
        self:addFlag(flag.position, flag.icon, flag.description)
      end
    end

    self.zoomMinimap = settings.zoom
    self.zoomFullmap = settings.zoomFull or settings.zoom

    self:setZoom(self.zoomMinimap)
  end
end

function UIMinimap:move(x, y)
  if self.isTransposedView and self:isTransposedView() then
    x, y = y, x
  end

  local cameraPos = self:getCameraPosition()
  local scale     = self:getScale()
  if scale > 1 then
    scale = 1
  end

  local dx = x / scale
  local dy = y / scale
  local pos = { x = cameraPos.x - dx, y = cameraPos.y - dy, z = cameraPos.z }
  self:setCameraPosition(pos)
end

function UIMinimap:refreshAlternativesPosition()
  for _, widget in pairs(self.alternatives) do
    if widget.pos then
      self:centerInPosition(widget, widget.pos)
    end
  end
end

function UIMinimap:reset()
  local player   = g_game.getLocalPlayer()
  local position = player and player:getPosition()

  if position then
    self:setCameraPosition(position)
  end
end

function UIMinimap:hideFloor()
  self.floorUpWidget:hide()
  self.floorDownWidget:hide()
end

function UIMinimap:hideZoom()
  self.zoomInWidget:hide()
  self.zoomOutWidget:hide()
end

function UIMinimap:setCrossPosition(pos)
  local cross = self.cross
  if not self.cross then
    cross = g_ui.createWidget('MinimapCross', self)
    cross:setIcon('/images/ui/minimap/cross')
    self.cross = cross
  end

  pos.z = self:getCameraPosition().z
  cross.pos = pos
  if pos then
    self:centerInPosition(cross, pos)
  else
    cross:breakAnchors()
  end
end

function UIMinimap:disableAutoWalk()
  self.autowalk = false
end



function UIMinimap:getFlag(mapPos)
  for _, flag in pairs(self.flags) do
    if flag.pos.x == mapPos.x and flag.pos.y == mapPos.y and flag.pos.z == mapPos.z then
      return flag
    end
  end
  return nil
end

function UIMinimap:addFlag(mapPos, icon, description, force, temporary)
  if not mapPos or not icon then
    return
  end

  local flag = self:getFlag(mapPos)
  if force then
    if flag then
      self:removeFlag(mapPos)
    end
  else
    if flag then
      return
    end
  end

  temporary = temporary or false

  flag = g_ui.createWidget('MinimapFlag')
  self:insertChild(1, flag)
  flag.pos = mapPos
  flag.description = description
  flag.icon = icon
  flag.temporary = temporary
  if type(tonumber(icon)) == 'number' then
    flag:setIcon('/images/ui/minimap/flag' .. icon)
  else
    flag:setIcon(resolvepath(icon, 1))
  end
  flag:setIconClip({ width = 11, height = 11 })
  flag:setTooltip(description)

  flag.onMouseRelease = function(widget, _pos, button)
    if button == MouseLeftButton then
      local player         = g_game.getLocalPlayer()
      local playerPosition = player and player:getPosition()

      if not playerPosition then
        return false
      end

      if Position.distance(playerPosition, widget.pos) > 250 then
        GameTextMessage.displayStatusMessage(loc'${GamelibInfoDestinationOutRange}')
        return false
      end

      if widget:getParent().autowalk then
        player:autoWalk(widget.pos)
      end

      return true

    elseif button == MouseRightButton then
      local menu = g_ui.createWidget('PopupMenu')
      menu:setGameMenu(true)
      menu:addOption(loc'${GamelibInfoOptionEditMark}', function() self:createEditFlagWindow(mapPos) end)
      menu:addOption(loc'${GamelibInfoOptionRemoveMark}', function() widget:destroy() end)
      menu:addSeparator()
      bindCopyPositionOption(menu, mapPos)
      menu:display(_pos)

      return true
    end

    return false
  end

  flag.onDestroy = function()
    table.removevalue(self.flags, flag)
  end

  table.insert(self.flags, flag)
  self:centerInPosition(flag, mapPos)
end

function UIMinimap:removeFlag(mapPos)
  local flag = self:getFlag(mapPos)
  if flag then
    flag:destroy()
  end
end



-- Attach data in widget before use this function: pos, alternativeId, temporary, description, minZoom, maxZoom
function UIMinimap:addAlternativeWidget(widget)
  local hasAlternativeWidget = table.contains(self.alternatives, widget)
  local hasChild             = self:hasChild(widget)

  if hasAlternativeWidget and hasChild then
    return

  else
    -- Ensure it is removed from both lists
    if hasAlternativeWidget then
      table.removevalue(self.alternatives, widget)
    end
    if hasChild then
      self:removeChild(widget)
    end
  end

  if self.alternativesVisible or widget.keepVisibleWhenAlternativesHidden then
    self:insertChild(1, widget)
  end

  if widget.description and widget:getStyleName() ~= 'CreatureButtonMinimapWidget' then
    widget:setTooltip(widget.description)
  end

  connect(widget, {
    onDestroy = function() table.removevalue(self.alternatives, widget, nil, true) end
  })

  self.alternatives[widget.alternativeId or tostring(widget:getId())] = widget
  self:centerInPosition(widget, widget.pos)
end

function UIMinimap:setAlternativeWidgetsVisible(show)
  local layout = self:getLayout()
  layout:disableUpdates()

  self.alternativesVisible = show

  for _, widget in pairs(self.alternatives) do
    if show or widget.keepVisibleWhenAlternativesHidden then
      if not self:hasChild(widget) then
        self:insertChild(1, widget)
        self:centerInPosition(widget, widget.pos)
      end

    else
      if self:hasChild(widget) then
        self:removeChild(widget)
      end
    end
  end

  layout:enableUpdates()
  layout:update()

  self:setCreatureMarkersExtraIconsVisible(show)
end

function UIMinimap:createCreatureMarker(markerTable, creatureId, color)
  local marker = g_ui.createWidget('CreatureButtonMinimapWidget')
  marker.creatureId = creatureId
  marker.baseHeight = marker:getHeight()
  marker.contentWidth = marker:getWidth()

  local creatureWidget = marker:getChildById('creatureWidget')
  marker.baseCreatureMarginTop = creatureWidget:getMarginTop()

  local markerDot = marker:getChildById('markerDot')
  marker.baseDotSize = markerDot:getWidth()
  marker.baseDotBorderWidth = markerDot:getBorderTopWidth()
  marker.baseDotMarginTop = markerDot:getMarginTop()
  markerDot:setBackgroundColor(color)

  connect(marker, {
    onDestroy = function()
      if markerTable[creatureId] == marker then
        markerTable[creatureId] = nil
      end
      if self.hoveredCreatureMarker == marker then
        self.hoveredCreatureMarker = nil
      end
    end
  })

  markerTable[creatureId] = marker
  self:insertChild(1, marker)
  return marker
end

function UIMinimap:updateCreatureMarkerData(marker, name, position, outfit)
  if not marker or not position then
    return false
  end

  marker.pos = {
    x = position.x,
    y = position.y,
    z = position.z
  }
  self:centerInPosition(marker, marker.pos)

  local creatureWidget = marker:getChildById('creatureWidget')
  local titleLabel = marker:getChildById('titleLabel')
  titleLabel:setText(name or '')
  marker.contentWidth = math.max(creatureWidget:getWidth(), titleLabel:getWidth() + 4)
  if outfit then
    creatureWidget:setOutfit(outfit)
    creatureWidget:setDirection(South)
  end

  self:updateCreatureMarkerVisibility(marker)
  return true
end

function UIMinimap:updateCreatureMarkerHover(pos, force)
  if pos then
    self.lastMousePos = pos
  end

  if not force and self:isDragging() then
    return
  end

  local hoveredMarker
  local mousePos = self.lastMousePos
  if self.isMinimapHovered and mousePos and
    self:isVisible() and self:containsPoint(mousePos) then
    local closestMarker, closestDistance = findClosestCreatureMarker(
      self.creatureMarkers or { }, mousePos, self.creatureMarkersExtraIcons)
    hoveredMarker, closestDistance = findClosestCreatureMarker(
      self.worldCreatureMarkers or { }, mousePos, self.creatureMarkersExtraIcons,
      closestMarker, closestDistance)

    if not hoveredMarker and self.hoveredCreatureMarker and self.hoveredCreatureMarker:isVisible() then
      local titleLabel = self.hoveredCreatureMarker:getChildById('titleLabel')
      if titleLabel and titleLabel:isVisible() and titleLabel:containsPoint(mousePos) then
        hoveredMarker = self.hoveredCreatureMarker
      end
    end
  end

  if hoveredMarker == self.hoveredCreatureMarker then
    if hoveredMarker then
      hoveredMarker:getChildById('titleLabel'):setVisible(true)
    end
    return
  end

  if self.hoveredCreatureMarker then
    self.hoveredCreatureMarker:getChildById('titleLabel'):setVisible(false)
  end

  self.hoveredCreatureMarker = hoveredMarker
  if hoveredMarker then
    hoveredMarker:getChildById('titleLabel'):setVisible(true)
  end
end

function UIMinimap:addCreatureMarker(creatureButton)
  if not creatureButton or not creatureButton.cid or not creatureButton.position then
    return false
  end

  local marker = self.creatureMarkers[creatureButton.cid]
  if not marker then
    marker = self:createCreatureMarker(self.creatureMarkers, creatureButton.cid, MinimapPartyMarkerColor)
  end

  local outfit = creatureButton.creature and creatureButton.creature:getOutfit() or creatureButton.outfit
  local updated = self:updateCreatureMarkerData(
    marker, creatureButton:getCreatureName(), creatureButton.position, outfit)
  self:updateCreatureMarkerHover()
  return updated
end

function UIMinimap:updateCreatureMarker(creatureButton)
  if not creatureButton or not creatureButton.cid or not creatureButton.position then
    return false
  end

  local marker = self.creatureMarkers[creatureButton.cid]
  if not marker then
    return false
  end

  local outfit = creatureButton.creature and creatureButton.creature:getOutfit() or creatureButton.outfit
  local updated = self:updateCreatureMarkerData(
    marker, creatureButton:getCreatureName(), creatureButton.position, outfit)
  self:updateCreatureMarkerHover()
  return updated
end

function UIMinimap:removeCreatureMarker(creatureId)
  local marker = self.creatureMarkers[creatureId]
  if not marker then
    return false
  end

  self.creatureMarkers[creatureId] = nil
  marker:destroy()
  self:updateCreatureMarkerHover()
  return true
end

function UIMinimap:clearCreatureMarkers()
  local creatureMarkers = self.creatureMarkers or { }
  self.creatureMarkers = { }

  for _, marker in pairs(creatureMarkers) do
    marker:destroy()
  end

  self:updateCreatureMarkerHover()
end

function UIMinimap:addWorldCreatureMarker(creature)
  if not creature or not creature.id or not creature.position or not creature.outfit then
    return false
  end

  local color
  if creature.type == CreatureTypeMonster then
    color = MinimapMonsterMarkerColor
  elseif creature.type == CreatureTypeNpc then
    color = MinimapNpcMarkerColor
  else
    return false
  end

  local marker = self.worldCreatureMarkers[creature.id]
  if not marker then
    marker = self:createCreatureMarker(self.worldCreatureMarkers, creature.id, color)
  else
    marker:getChildById('markerDot'):setBackgroundColor(color)
  end

  local updated = self:updateCreatureMarkerData(marker, creature.name, creature.position, creature.outfit)
  if updated then
    marker.seenInSnapshot = true
  end
  return updated
end

function UIMinimap:clearWorldCreatureMarkers()
  local worldCreatureMarkers = self.worldCreatureMarkers or { }
  self.worldCreatureMarkers = { }

  for _, marker in pairs(worldCreatureMarkers) do
    marker:destroy()
  end

  self:updateCreatureMarkerHover()
end

function UIMinimap:addWorldCreatureSnapshotChunk(creatures, isFirstChunk, isLastChunk)
  local layout = self:getLayout()
  layout:disableUpdates()

  if isFirstChunk then
    for _, marker in pairs(self.worldCreatureMarkers) do
      marker.seenInSnapshot = false
    end
  end

  for _, creature in ipairs(creatures) do
    self:addWorldCreatureMarker(creature)
  end

  if isLastChunk then
    for creatureId, marker in pairs(self.worldCreatureMarkers) do
      if marker.seenInSnapshot then
        marker.seenInSnapshot = nil
      else
        self.worldCreatureMarkers[creatureId] = nil
        marker:destroy()
      end
    end
  end

  layout:enableUpdates()
  layout:update()
  self:updateCreatureMarkerHover()
end

function UIMinimap:setCreatureMarkersExtraIconsVisible(show)
  self.creatureMarkersExtraIcons = show
  self:refreshCreatureMarkers()
end

function UIMinimap:updateCreatureMarkerVisibility(marker)
  local cameraPosition = self:getCameraPosition()
  local isCurrentFloor = marker.pos and marker.pos.z == cameraPosition.z
  local isCloseEnough = self:getZoom() >= getCreatureMarkerMinimumZoom(self)
  local creatureWidget = marker:getChildById('creatureWidget')
  local markerDot = marker:getChildById('markerDot')
  local markerWidth = marker.contentWidth or marker:getWidth()
  local baseHeight = marker.baseHeight or marker:getHeight()
  local markerHeight = baseHeight
  local dotSize = marker.baseDotSize or markerDot:getWidth()
  local dotBorderWidth = marker.baseDotBorderWidth or markerDot:getBorderTopWidth()
  local dotMarginTop = marker.baseDotMarginTop or markerDot:getMarginTop()
  local creatureMarginTop = marker.baseCreatureMarginTop or creatureWidget:getMarginTop()

  if not self.creatureMarkersExtraIcons then
    local scale = self:getScale()
    dotSize = math.max(1, math.floor(dotSize * scale + 0.5))
    dotBorderWidth = math.max(0, math.floor(dotBorderWidth * scale + 0.5))
    markerWidth = math.max(markerWidth, dotSize)
    markerHeight = math.max(markerHeight, dotSize)
    dotMarginTop = math.floor((markerHeight - dotSize) / 2 + 0.5)
    creatureMarginTop = creatureMarginTop + math.floor((markerHeight - baseHeight) / 2)
  end

  if marker:getWidth() ~= markerWidth then
    marker:setWidth(markerWidth)
  end
  if marker:getHeight() ~= markerHeight then
    marker:setHeight(markerHeight)
  end
  if markerDot:getWidth() ~= dotSize then
    markerDot:setWidth(dotSize)
  end
  if markerDot:getHeight() ~= dotSize then
    markerDot:setHeight(dotSize)
  end
  if markerDot:getBorderTopWidth() ~= dotBorderWidth then
    markerDot:setBorderWidth(dotBorderWidth)
  end
  if markerDot:getMarginTop() ~= dotMarginTop then
    markerDot:setMarginTop(dotMarginTop)
  end
  if creatureWidget:getMarginTop() ~= creatureMarginTop then
    creatureWidget:setMarginTop(creatureMarginTop)
  end

  marker:setVisible(isCurrentFloor and isCloseEnough)
  creatureWidget:setVisible(self.creatureMarkersExtraIcons)
  marker:getChildById('titleLabel'):setVisible(
    self.isMinimapHovered and marker == self.hoveredCreatureMarker)
  markerDot:setVisible(not self.creatureMarkersExtraIcons)
end

function UIMinimap:refreshCreatureMarkers()
  for _, markerTable in ipairs({ self.creatureMarkers or { }, self.worldCreatureMarkers or { } }) do
    for _, marker in pairs(markerTable) do
      if marker.pos then
        self:updateCreatureMarkerVisibility(marker)
      end
    end
  end

  self:updateCreatureMarkerHover()
end

function UIMinimap:getCreatureSnapshotRequest()
  if self:getZoom() < getCreatureMarkerMinimumZoom(self) then
    return nil
  end

  local position = self:getCameraPosition()
  local scale = self:getScale()
  local width = self:getWidth()
  local height = self:getHeight()
  if not position or scale <= 0 or width <= 0 or height <= 0 then
    return nil
  end

  if self.isTransposedView and self:isTransposedView() then
    width, height = height, width
  end

  return {
    position = { x = position.x, y = position.y, z = position.z },
    rangeX = math.ceil(width / (2 * scale)) + 1,
    rangeY = math.ceil(height / (2 * scale)) + 1
  }
end



function UIMinimap:createAddFlagWindow(mapPos)
  if self.addFlagWindow or not mapPos then
    return
  end

  self.addFlagWindow = g_ui.createWidget('MinimapAddFlagWindow', rootWidget)

  local positionLabel = self.addFlagWindow:getChildById('position')
  local description   = self.addFlagWindow:getChildById('description')
  local okButton      = self.addFlagWindow:getChildById('okButton')
  local cancelButton  = self.addFlagWindow:getChildById('cancelButton')

  local flagRadioGroup = UIRadioGroup.create()

  for i = 0, 19 do
    local checkbox = self.addFlagWindow:getChildById('flag' .. i)
    checkbox.icon = i
    flagRadioGroup:addWidget(checkbox)
  end

  positionLabel:setText(f('%i, %i, %i', mapPos.x, mapPos.y, mapPos.z))
  flagRadioGroup:selectWidget(flagRadioGroup:getFirstWidget())

  local successFunc = function()
    self:addFlag(mapPos, flagRadioGroup:getSelectedWidget().icon, description:getText())
    self:destroyAddFlagWindow()
  end

  local cancelFunc = function()
    self:destroyAddFlagWindow()
  end

  okButton.onClick     = successFunc
  cancelButton.onClick = cancelFunc

  self.addFlagWindow.onEnter   = successFunc
  self.addFlagWindow.onEscape  = cancelFunc
  self.addFlagWindow.onDestroy = function() flagRadioGroup:destroy() end
end

function UIMinimap:destroyAddFlagWindow()
  if self.addFlagWindow then
    self.addFlagWindow:destroy()
    self.addFlagWindow = nil
  end
end

function UIMinimap:createEditFlagWindow(mapPos)
  if self.editFlagWindow or not mapPos then
    return
  end

  local flag = self:getFlag(mapPos)
  if not flag then
    return
  end

  self.editFlagWindow = g_ui.createWidget('MinimapEditFlagWindow', rootWidget)

  local positionLabel = self.editFlagWindow:getChildById('position')
  local description   = self.editFlagWindow:getChildById('description')
  local okButton      = self.editFlagWindow:getChildById('okButton')
  local cancelButton  = self.editFlagWindow:getChildById('cancelButton')

  local flagRadioGroup = UIRadioGroup.create()

  for i = 0, 19 do
    local checkbox = self.editFlagWindow:getChildById('flag' .. i)
    checkbox.icon = i
    flagRadioGroup:addWidget(checkbox)
  end

  positionLabel:setText(f('%i, %i, %i', mapPos.x, mapPos.y, mapPos.z))
  description:setText(flag.description)
  flagRadioGroup:selectWidget(flagRadioGroup.widgets[flag.icon + 1])

  local successFunc = function()
    self:addFlag(mapPos, flagRadioGroup:getSelectedWidget().icon, description:getText(), true)
    self:destroyEditFlagWindow()
  end

  local cancelFunc = function()
    self:destroyEditFlagWindow()
  end

  okButton.onClick     = successFunc
  cancelButton.onClick = cancelFunc

  self.editFlagWindow.onEnter   = successFunc
  self.editFlagWindow.onEscape  = cancelFunc
  self.editFlagWindow.onDestroy = function() flagRadioGroup:destroy() end
end

function UIMinimap:destroyEditFlagWindow()
  if self.editFlagWindow then
    self.editFlagWindow:destroy()
    self.editFlagWindow = nil
  end
end



function UIMinimap:onVisibilityChange()
  if not self:isVisible() then
    self.isMinimapHovered = false
    self:updateCreatureMarkerHover(nil, true)
    self:destroyAddFlagWindow()
    self:destroyEditFlagWindow()
  end
end

function UIMinimap:onCameraPositionChange(cameraPos, oldCameraPos)
  if self.cross then
    self:setCrossPosition(self.cross.pos)
  end

  if not oldCameraPos or oldCameraPos.z ~= cameraPos.z then
    self:refreshCreatureMarkers()
  else
    self:updateCreatureMarkerHover()
  end

  if GameMinimap and GameMinimap.requestCreatureSnapshot then
    GameMinimap.requestCreatureSnapshot()
  end
end

function UIMinimap:onZoomChange(zoom) -- zoom is from maxZoom -5 (far) to minZoom 5 (near)
  if self.fullMapView then
    self.zoomFullmap = zoom
  else
    self.zoomMinimap = zoom
  end

  for _,widget in pairs(self.alternatives or {}) do
    if (not widget.minZoom or widget.minZoom >= zoom) and (widget.maxZoom or 0) <= zoom then
      widget:show()
    else
      widget:hide()
    end
  end

  self:refreshCreatureMarkers()

  if GameMinimap and GameMinimap.requestCreatureSnapshot then
    GameMinimap.requestCreatureSnapshot()
  end
end

function UIMinimap:onMouseWheel(mousePos, direction)
  local keyboardModifiers = g_keyboard.getModifiers()
  if direction == MouseWheelUp and keyboardModifiers == KeyboardNoModifier then
    self:zoomIn()
  elseif direction == MouseWheelDown and keyboardModifiers == KeyboardNoModifier then
    self:zoomOut()
  elseif direction == MouseWheelDown and keyboardModifiers == KeyboardCtrlModifier then
    self:floorUp(1)
  elseif direction == MouseWheelUp and keyboardModifiers == KeyboardCtrlModifier then
    self:floorDown(1)
  end
end

function UIMinimap:onMouseMove(pos, moved)
  local previousPos = self.lastMousePos
  self.lastMousePos = pos
  if previousPos and previousPos.x == pos.x and previousPos.y == pos.y then
    return false
  end

  self:updateCreatureMarkerHover(pos)
  return false
end

function UIMinimap:onHoverChange(hovered)
  self.isMinimapHovered = hovered
  self:updateCreatureMarkerHover()
end

function UIMinimap:onMousePress(pos, button)
  if not self:isDragging() then
    self.allowNextRelease = true
  end
end

function UIMinimap:onMouseRelease(pos, button)
  if not self.allowNextRelease then
    return true
  end

  self.allowNextRelease = false

  local mapPos = self:getTilePosition(pos)
  if not mapPos then
    return false
  end

  if button == MouseLeftButton then
    local isJumpModeEnabled = GameMinimap and GameMinimap.isJumpModeEnabled and GameMinimap.isJumpModeEnabled()
    if g_game.getGroupAccess() and (isJumpModeEnabled or (g_keyboard.isCtrlPressed() and g_keyboard.isShiftPressed())) then
      return g_game.sendGmTeleport(mapPos)
    end

    local player         = g_game.getLocalPlayer()
    local playerPosition = player and player:getPosition()
    if not playerPosition then
      return false
    end

    if Position.distance(playerPosition, mapPos) > 250 then
    	GameTextMessage.displayStatusMessage(loc'${GamelibInfoDestinationOutRange}')
    	return false
    end

    if self.autowalk then
      player:autoWalk(mapPos)
    end

    return true

  elseif button == MouseRightButton then
    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)
    menu:addOption(loc'${GamelibInfoOptionAddNewMark}', function() self:createAddFlagWindow(mapPos) end)
    if GameTracker then
      menu:addOption(loc'${GamelibInfoOptionTrackPos}', function() signalcall(g_game.onClickStartTrackPosition, mapPos) end)
      menu:addOption(loc'${GamelibInfoOptionTrackCustomPos}', function() GameTracker.createTrackByPosWindow(mapPos) end)
    end
    menu:addSeparator()
    bindCopyPositionOption(menu, mapPos)
    menu:display(pos)

    return true
  end

  return false
end

function UIMinimap:onDragEnter(pos)
  self.dragReference = pos
  self.dragCameraReference = self:getCameraPosition()
  self:updateCreatureMarkerHover(pos)
  return true
end

function UIMinimap:onDragMove(pos, moved)
  local mousePos = pos
  local scale = self:getScale()
  local dx = (self.dragReference.x - pos.x) / scale
  local dy = (self.dragReference.y - pos.y) / scale

  if self.isTransposedView and self:isTransposedView() then
    dx, dy = dy, dx
  end

  local cameraPosition = {
    x = self.dragCameraReference.x + dx,
    y = self.dragCameraReference.y + dy,
    z = self.dragCameraReference.z
  }
  self:setCameraPosition(cameraPosition)
  self:updateCreatureMarkerHover(mousePos, true)
  return true
end

function UIMinimap:onDragLeave(widget, pos)
  self:updateCreatureMarkerHover(pos, true)
  return true
end

function UIMinimap:onStyleApply(styleName, styleNode)
  for name, value in pairs(styleNode) do
    if name == 'autowalk' then
      self.autowalk = value
    end
  end
end
