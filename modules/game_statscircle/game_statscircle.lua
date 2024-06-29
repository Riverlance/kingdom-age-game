_G.GameStatsCircle = { }

Stats = {
  None       = 0,
  Health     = 1,
  Mana       = 2,
  Vigor      = 3,
  Boost      = 4,
  Capacity   = 5,
  Experience = 6,
  Any        = 9,
}

statsCircle = nil

leftArc   = nil
rightArc  = nil
topArc    = nil
bottomArc = nil

arcSettings = nil
optionPanel = nil

size               = g_settings.getNumber('stats_circle_size', 1.00)
gameScreenBased    = g_settings.getBoolean('stats_circle_gamescreenbased', false)
distanceFromCenter = g_settings.getNumber('stats_circle_distfromcenter', 0.00)
opacityCircleFill  = g_settings.getNumber('stats_circle_fillopacity', 1.00)
opacityCircleBg    = g_settings.getNumber('stats_circle_bgopacity', 0.70)



function GameStatsCircle.init()
  -- Alias
  GameStatsCircle.m = modules.game_statscircle

  local mapPanel = GameInterface.getMapPanel()

  statsCircle = g_ui.loadUI('game_statscircle', mapPanel)

  leftArc   = statsCircle.leftArc
  rightArc  = statsCircle.rightArc
  topArc    = statsCircle.topArc
  bottomArc = statsCircle.bottomArc

  -- load defaults
  leftArc.statsType   = Stats.Health
  rightArc.statsType  = Stats.Mana
  topArc.statsType    = Stats.None
  bottomArc.statsType = Stats.None

  arcs = { leftArc, rightArc, topArc, bottomArc }

  baseImageSizeThin  = leftArc:getWidth()
  baseImageSizeBroad = leftArc:getHeight()
  imageSizeThin      = baseImageSizeThin * 1.
  imageSizeBroad     = baseImageSizeBroad * 1.

  connect(g_game, {
    onGameStart = GameStatsCircle.onGameStart,
    onGameEnd   = GameStatsCircle.onGameEnd,
  })

  connect(mapPanel, {
    onGeometryChange = GameStatsCircle.onGeometryChange,
    onViewModeChange = GameStatsCircle.onViewModeChange,
    onZoomChange     = GameStatsCircle.onZoomChange,
  })

  connect(LocalPlayer, {
    onHealthChange       = GameStatsCircle.onHealthChange,
    onManaChange         = GameStatsCircle.onManaChange,
    onVigorChange        = GameStatsCircle.onVigorChange,
    onFreeCapacityChange = GameStatsCircle.onFreeCapacityChange,
    onExperienceChange   = GameStatsCircle.onExperienceChange,
    onVocationChange     = GameStatsCircle.onVocationChange,
  })
end

function GameStatsCircle.terminate()
  statsCircle:destroy()

  statsCircle = nil

  leftArc   = nil
  rightArc  = nil
  topArc    = nil
  bottomArc = nil

  optionPanel = nil

  disconnect(LocalPlayer, {
    onHealthChange       = GameStatsCircle.onHealthChange,
    onManaChange         = GameStatsCircle.onManaChange,
    onVigorChange        = GameStatsCircle.onVigorChange,
    onFreeCapacityChange = GameStatsCircle.onFreeCapacityChange,
    onExperienceChange   = GameStatsCircle.onExperienceChange,
    onVocationChange     = GameStatsCircle.onVocationChange,
  })

  disconnect(GameInterface.getMapPanel(), {
    onGeometryChange = GameStatsCircle.onGeometryChange,
    onViewModeChange = GameStatsCircle.onViewModeChange,
    onZoomChange     = GameStatsCircle.onZoomChange,
  })

  disconnect(g_game, {
    onGameStart = GameStatsCircle.onGameStart,
    onGameEnd   = GameStatsCircle.onGameEnd,
  })

  GameStatsCircle = { }
end



function GameStatsCircle.onGameStart()
  arcSettings = { }

  GameStatsCircle.loadPlayerSettings()
  GameStatsCircle.enableOptionsPanel()

  GameStatsCircle.setSize(size)
  GameStatsCircle.setDistanceFromCenter(distanceFromCenter)
  GameStatsCircle.setCircleFillOpacity(opacityCircleFill)
  GameStatsCircle.setCircleBackgroundOpacity(opacityCircleBg)

  GameStatsCircle.update()
end

function GameStatsCircle.onGameEnd()
  GameStatsCircle.savePlayerSettings()
  GameStatsCircle.disableOptionsPanel()

  arcSettings = { }
end



function GameStatsCircle.loadPlayerSettings()
  local settings = Client.getPlayerSettings():getNode('StatsCircle') or { }
  for arcNode, _ in pairs(settings) do
    local arc = GameStatsCircle.m[arcNode]
    arc.statsType = settings[arcNode].statsType or arc.statsType
    arcSettings[arcNode] = arc.statsType
  end
end

function GameStatsCircle.savePlayerSettings()
  local arcSettings = { }
  for _, arcWidget in ipairs(arcs) do
    arcSettings[arcWidget:getId()] = { statsType = arcWidget.statsType }
  end

  local settings = Client.getPlayerSettings()
  settings:setNode('StatsCircle', arcSettings)
  settings:save()
end

function GameStatsCircle.currentViewMode()
  return GameInterface.m.currentViewMode
end



function GameStatsCircle.onHealthChange()
  GameStatsCircle.updateCircle(Stats.Health)
end

function GameStatsCircle.onManaChange()
  GameStatsCircle.updateCircle(Stats.Mana)
end

function GameStatsCircle.onVigorChange()
  GameStatsCircle.updateCircle(Stats.Vigor)
end

function GameStatsCircle.onFreeCapacityChange()
  GameStatsCircle.updateCircle(Stats.Capacity)
end

function GameStatsCircle.onExperienceChange()
  GameStatsCircle.updateCircle(Stats.Experience)
end

function GameStatsCircle.onVocationChange(creature, vocation, oldVocation)
  local localPlayer = g_game.getLocalPlayer()
  if creature ~= localPlayer then
    return
  end

  GameStatsCircle.updateArcsComboBox()
end

function GameStatsCircle.onGeometryChange(self)
  if g_game.isOnline() then
    GameStatsCircle.update()
  end
end

function GameStatsCircle.onViewModeChange(mapWidget, newMode, oldMode)
  if g_game.isOnline() then
    GameStatsCircle.update()
  end
end

function GameStatsCircle.onZoomChange(self, oldZoom, newZoom)
  if g_game.isOnline() then
    GameStatsCircle.update()
  end
end



function GameStatsCircle.update()
  addEvent(function()
    GameStatsCircle.setSize(sizeScrollbar:getValue())
  end)
end

function GameStatsCircle.updateCircle(statsType, percent)
  for _, arcWidget in pairs(arcs) do
    if statsType == Stats.Any or arcWidget.statsType == statsType then
      GameStatsCircle.updateArc(arcWidget, percent)
    end
  end
end

function GameStatsCircle.setArcStatsType(arc, statsType)
  arc.statsType = statsType
  GameStatsCircle.updateArc(arc)
end

function GameStatsCircle.updateArc(arc, percent)
  arc:setVisible(arc.statsType > Stats.None)

  if arc.statsType == Stats.None then
    return
  end

  local p = g_game.getLocalPlayer()
  if arc.statsType == Stats.Health then
    percent = percent or p:getHealthPercent()
    color = '#FF4444'
  elseif arc.statsType == Stats.Mana then
    percent = percent or 100 * p:getMana() / p:getMaxMana()
    color = '#AA44FF'
  elseif arc.statsType == Stats.Vigor then
    percent = percent or 100 * p:getVigor() / p:getMaxVigor()
    color = '#FFA14F'
  elseif arc.statsType == Stats.Capacity then
    percent = percent or 100 * p:getFreeCapacity() / p:getTotalCapacity()
    color = '#4FACFF'
  elseif arc.statsType == Stats.Experience then
    percent = percent or p:getLevelPercent()
    color = '#8BE866'
  end

  if arc.isVertical then
    arc.bg:setSize({ width = imageSizeThin, height = imageSizeBroad })
    arc.fill:setImageClip({
      x      = 0,
      y      = (100 - percent) * baseImageSizeBroad * .01,
      width  = baseImageSizeThin,
      height = baseImageSizeBroad * percent * .01,
    })
    arc.fill:setWidth(imageSizeThin)
    arc.fill:setHeight(percent * imageSizeBroad * .01)

  elseif arc.isHorizontal then
    arc.bg:setSize({ width = imageSizeBroad, height = imageSizeThin })
    arc.fill:setImageClip({
      x      = 0,
      y      = 0,
      width  = percent * baseImageSizeBroad * .01,
      height = baseImageSizeThin,
    })
    arc.fill:setWidth(percent * imageSizeBroad * .01)
    arc.fill:setHeight(imageSizeThin)
  end

  arc.fill:setImageColor(color)
end

function GameStatsCircle.setSize(value)
  local ratio = gameScreenBasedCheckBox:isChecked() and GameInterface.getMapPanel():getStretchRatio() or 1

  imageSizeThin  = baseImageSizeThin * (value * .01) * ratio
  imageSizeBroad = baseImageSizeBroad * (value * .01) * ratio

  GameStatsCircle.updateCircle(Stats.Any)

  g_settings.set('stats_circle_size', value)
end

function GameStatsCircle.setGameScreenBased(checked)
  g_settings.set('stats_circle_gamescreenbased', checked)

  GameStatsCircle.update()
end

function GameStatsCircle.setDistanceFromCenter(value)
  local size = 354 + math.floor(value * 1.5)
  statsCircle:setSize({ width = size, height = size })
  g_settings.set('stats_circle_distfromcenter', value)

  GameStatsCircle.update()
end

function GameStatsCircle.setCircleFillOpacity(value)
  leftArc.fill:setOpacity(value)
  rightArc.fill:setOpacity(value)
  topArc.fill:setOpacity(value)
  bottomArc.fill:setOpacity(value)

  g_settings.set('stats_circle_fillopacity', value)
end

function GameStatsCircle.setCircleBackgroundOpacity(value)
  leftArc.bg:setOpacity(value)
  rightArc.bg:setOpacity(value)
  topArc.bg:setOpacity(value)
  bottomArc.bg:setOpacity(value)

  g_settings.set('stats_circle_bgopacity', value)
end



-- Option Settings

optionPanel             = nil
leftArcComboBox         = nil
rightArcComboBox        = nil
topArcComboBox          = nil
bottomArcComboBox       = nil
sizeScrollbar           = nil
gameScreenBasedCheckBox = nil
distFromCenScrollbar    = nil
fillOpacityScrollbar    = nil
bgOpacityScrollbar      = nil

function GameStatsCircle.updateArcsComboBox()
  local localPlayer   = g_game.getLocalPlayer()
  local isManaEnabled = not localPlayer or not localPlayer:isWarrior()

  for arcPos, comboBox in ipairs(arcsComboBox or { }) do
    comboBox:clearOptions()

    comboBox:addOption(tr('None'), Stats.None)
    comboBox:addOption(tr('Health'), Stats.Health)
    if isManaEnabled then
      comboBox:addOption(tr('Mana'), Stats.Mana)
    end
    comboBox:addOption(tr('Vigor'), Stats.Vigor)
    comboBox:addOption(tr('Capacity'), Stats.Capacity)
    comboBox:addOption(tr('Experience'), Stats.Experience)
    comboBox:setCurrentOptionByData(arcSettings[comboBox.arc:getId()])
  end
end

function GameStatsCircle.enableOptionsPanel()
  -- Add to options module
  optionPanel = g_ui.loadUI('option_statscircle')
  ClientOptions.addTab(tr('Stats Circle'), optionPanel, '/images/ui/options/stats_circle')

  -- UI values
  leftArcComboBox   = optionPanel:recursiveGetChildById('leftArcComboBox')
  rightArcComboBox  = optionPanel:recursiveGetChildById('rightArcComboBox')
  topArcComboBox    = optionPanel:recursiveGetChildById('topArcComboBox')
  bottomArcComboBox = optionPanel:recursiveGetChildById('bottomArcComboBox')

  leftArcComboBox.arc   = leftArc
  rightArcComboBox.arc  = rightArc
  topArcComboBox.arc    = topArc
  bottomArcComboBox.arc = bottomArc

  arcsComboBox = { leftArcComboBox, rightArcComboBox, topArcComboBox, bottomArcComboBox }

  sizeScrollbar           = optionPanel:recursiveGetChildById('sizeScrollbar')
  gameScreenBasedCheckBox = optionPanel:recursiveGetChildById('gameScreenBasedCheckBox')
  distFromCenScrollbar    = optionPanel:recursiveGetChildById('distFromCenScrollbar')
  fillOpacityScrollbar    = optionPanel:recursiveGetChildById('fillOpacityScrollbar')
  bgOpacityScrollbar      = optionPanel:recursiveGetChildById('bgOpacityScrollbar')

  GameStatsCircle.updateArcsComboBox()

  sizeScrollbar:setValue(size)
  gameScreenBasedCheckBox:setChecked(gameScreenBased)
  distFromCenScrollbar:setValue(distanceFromCenter)
  fillOpacityScrollbar:setValue(opacityCircleFill * 100)
  bgOpacityScrollbar:setValue(opacityCircleBg * 100)
end

function GameStatsCircle.disableOptionsPanel()
  leftArcComboBox         = nil
  rightArcComboBox        = nil
  topArcComboBox          = nil
  bottomArcComboBox       = nil
  arcsComboBox            = nil
  sizeScrollbar           = nil
  gameScreenBasedCheckBox = nil
  distFromCenScrollbar    = nil
  fillOpacityScrollbar    = nil
  bgOpacityScrollbar      = nil

  ClientOptions.removeTab(tr('Stats Circle'))
  optionPanel = nil
end
