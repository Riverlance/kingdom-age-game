local enabled = g_gameConfig.isDrawingInformationByWidget()
if enabled then
  g_logger.warning('Creature Information By Widget is enabled. (performance may be degraded)')
end

local devMode = false
local debug = false

local COVERED_COLOR = '#606060'
local NPC_COLOR = '#66CCFF'

local function onCreate(creature)
  local widget = g_ui.loadUI('creatureinformation')

  if debug then
    widget:setBorderColor('red')
    widget:setBorderWidth(2)
    widget.icons:setBorderColor('yellow')
    widget.icons:setBorderWidth(2)
  end

  widget.manaBar:setVisible(creature:isLocalPlayer())
  creature:setWidgetInformation(widget)

  local nameShader = creature:getNameShader()
  if nameShader and nameShader ~= '' then
    local widgetShader = nameShader
    if widgetShader:sub(1, 10) == 'Outline - ' then
      widgetShader = 'Widget - ' .. widgetShader
    end
    widget.name:setShader(widgetShader)
  end
end

local function onHealthPercentChange(creature, healthPercent)
  local gameMapPanel = GameInterface.getMapPanel()
  local widget = creature:getWidgetInformation()
  if not widget then
    return
  end

  local color
  if healthPercent > 92 then
    color = '#00BC00'
  elseif healthPercent > 60 then
    color = '#50A150'
  elseif healthPercent > 30 then
    color = '#A1A100'
  elseif healthPercent > 8 then
    color = '#BF0A0A'
  elseif healthPercent > 3 then
    color = '#910F0F'
  else
    color = '#850C0F'
  end

  widget.name:setColor(color)
  widget.lifeBar:setPercent(healthPercent)
  widget.lifeBar:setBackgroundColor(color)
  widget.lifeBar:setVisible(gameMapPanel:isDrawingHealthBars())
end

local function onManaChange(player, mana, maxMana)
  local gameMapPanel = GameInterface.getMapPanel()
  local widget = player:getWidgetInformation()
  if not widget then
    return
  end

  if player:getMaxMana() > 1 and maxMana > 0 then
    widget.manaBar:setPercent((mana / maxMana) * 100)
  else
    widget.manaBar:setPercent(1)
  end

  widget.manaBar:setVisible(gameMapPanel:isDrawingManaBar())
end

local function onChangeName(creature, name)
  local gameMapPanel = GameInterface.getMapPanel()
  local infoWidget = creature:getWidgetInformation()
  if not infoWidget then
    return
  end

  if g_game.getFeature(GameBlueNpcNameColor) and creature:isNpc() and creature:isFullHealth() then
    infoWidget.name:setColor(NPC_COLOR)
  end

  infoWidget.name:setText(name)
  infoWidget.name:setVisible(gameMapPanel:isDrawingNames())
end

local function onCovered(creature, isCovered)
  local infoWidget = creature:getWidgetInformation()
  if not infoWidget then
    return
  end

  if isCovered then
    infoWidget.name:setColor(COVERED_COLOR)
    infoWidget.lifeBar:setBackgroundColor(COVERED_COLOR)
  else
    onHealthPercentChange(creature, creature:getHealthPercent())
  end
end

local function onOutfitChange(creature)
  -- Keep the widget anchored by its UI definition. The custom client does
  -- not expose the upstream crop-size configuration option.
end

local function blinkIcon(icon, ticks)
  if icon:isDestroyed() then
    return
  end

  icon:setVisible(not icon:isVisible())
  scheduleEvent(function()
    blinkIcon(icon, ticks)
  end, ticks)
end

local function setIcon(creature, id, getIconPath, typeIcon)
  local setParentAnchor = function(widget)
    widget:addAnchor(AnchorTop, 'parent', AnchorTop)
    widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  end

  local infoWidget = creature:getWidgetInformation()
  if not infoWidget then
    return
  end

  local oldIcon = infoWidget.icons[typeIcon]
  if oldIcon then
    local index = oldIcon:getChildIndex()
    oldIcon:destroy()

    if index == 1 and infoWidget.icons:hasChildren() then
      setParentAnchor(infoWidget.icons:getChildByIndex(index))
    end
  end

  local hasChildren = infoWidget.icons:hasChildren()
  local path, blink = getIconPath(id)
  if path == nil or path == '' then
    if not hasChildren then
      infoWidget.icons:setVisible(false)
    end
    return
  end

  local icon = g_ui.createWidget('IconInformation', infoWidget.icons)
  icon:setId(typeIcon)
  icon:setImageSource(path)

  if not hasChildren then
    setParentAnchor(icon)
    infoWidget.icons:setVisible(true)
  end

  if blink then
    blinkIcon(icon, g_gameConfig.getShieldBlinkTicks())
  end
end

local creatureEvents = {
  onCreate = onCreate,
  onOutfitChange = onOutfitChange,
  onCovered = onCovered,
  onHealthPercentChange = onHealthPercentChange,
  onChangeName = onChangeName,
  onTypeChange = function(creature, id) setIcon(creature, id, getCreatureTypeImagePath, 'type') end,
  onSpeechBubbleChange = function(creature, id) setIcon(creature, id, getSpeechBubbleImagePath, 'speechBubble') end,
  onSkullChange = function(creature, id) setIcon(creature, id, getSkullImagePath, 'skull') end,
  onShieldChange = function(creature, id) setIcon(creature, id, getShieldImagePathAndBlink, 'shield') end,
  onEmblemChange = function(creature, id) setIcon(creature, id, getEmblemImagePath, 'emblem') end,
  onSpecialIconChange = function(creature, id) setIcon(creature, id, getSpecialIconPath, 'specialIcon') end,
}

local localPlayerEvents = { onManaChange = onManaChange }

function toggleInformation()
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer or not localPlayer:getWidgetInformation() then
    return
  end

  local gameMapPanel = GameInterface.getMapPanel()
  localPlayer:getWidgetInformation().manaBar:setVisible(gameMapPanel:isDrawingManaBar())

  for _, creature in ipairs(gameMapPanel:getSpectators()) do
    local widget = creature:getWidgetInformation()
    if widget then
      widget.name:setVisible(gameMapPanel:isDrawingNames())
      widget.lifeBar:setVisible(gameMapPanel:isDrawingHealthBars())
    end
  end
end

function init()
  if not enabled then
    return
  end

  connect(Creature, creatureEvents)
  connect(LocalPlayer, localPlayerEvents)
end

function terminate()
  if not enabled then
    return
  end

  disconnect(Creature, creatureEvents)
  disconnect(LocalPlayer, localPlayerEvents)
end

if devMode and enabled then
  connect(g_game, {
    onGameStart = function()
      for _, creature in ipairs(GameInterface.getMapPanel():getSpectators()) do
        onCreate(creature)
      end
    end
  })
end
