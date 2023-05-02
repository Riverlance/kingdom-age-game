_G.GameAttributes = { }



attributeWindow        = nil
attributeFooter        = nil
attributeTopMenuButton = nil

attackAttributeAddButton       = nil
defenseAttributeAddButton      = nil
magicDefenseAttributeAddButton = nil
vitalityAttributeAddButton     = nil
willPowerAttributeAddButton    = nil
agilityAttributeAddButton      = nil
dodgeAttributeAddButton        = nil
walkingAttributeAddButton      = nil
luckAttributeAddButton         = nil

attackAttributeLabel       = nil
defenseAttributeLabel      = nil
magicDefenseAttributeLabel = nil
vitalityAttributeLabel     = nil
willPowerAttributeLabel    = nil
agilityAttributeLabel      = nil
dodgeAttributeLabel        = nil
walkingAttributeLabel      = nil
luckAttributeLabel         = nil

attackAttributeActLabel       = nil
defenseAttributeActLabel      = nil
magicDefenseAttributeActLabel = nil
vitalityAttributeActLabel     = nil
willPowerAttributeActLabel    = nil
agilityAttributeActLabel      = nil
dodgeAttributeActLabel        = nil
walkingAttributeActLabel      = nil
luckAttributeActLabel         = nil

availablePointsLabel = nil
pointsCostLabel      = nil

ATTRIBUTE_NONE         = 0
ATTRIBUTE_ATTACK       = 1
ATTRIBUTE_DEFENSE      = 2
ATTRIBUTE_MAGICDEFENSE = 3
ATTRIBUTE_VITALITY     = 4
ATTRIBUTE_WILLPOWER    = 5
ATTRIBUTE_AGILITY      = 6 -- Limited to 100 points
ATTRIBUTE_DODGE        = 7 -- Limited to 100 points
ATTRIBUTE_WALKING      = 8 -- Limited to 100 points
ATTRIBUTE_LUCK         = 9 -- Limited to 100 points
ATTRIBUTE_FIRST        = ATTRIBUTE_ATTACK
ATTRIBUTE_LAST         = ATTRIBUTE_LUCK

attributeLabel    = nil
attributeActLabel = nil

local attribute_flag_updateList = -1

local _availablePoints = 0



function GameAttributes.init()
  -- Alias
  GameAttributes.m = modules.ka_game_attributes

  g_keyboard.bindKeyDown('Ctrl+Shift+U', GameAttributes.toggle)

  attributeWindow        = g_ui.loadUI('attributes')
  attributeFooter        = attributeWindow:getChildById('miniWindowFooter')
  attributeTopMenuButton = ClientTopMenu.addRightGameToggleButton('attributeTopMenuButton', tr('Attributes') .. ' (Ctrl+Shift+U)', '/images/ui/top_menu/attributes', GameAttributes.toggle)

  attributeWindow.topMenuButton = attributeTopMenuButton
  attributeWindow:disableResize()

  local contentsPanel = attributeWindow:getChildById('contentsPanel')

  attackAttributeAddButton       = contentsPanel:getChildById('attackAttributeAddButton')
  defenseAttributeAddButton      = contentsPanel:getChildById('defenseAttributeAddButton')
  magicDefenseAttributeAddButton = contentsPanel:getChildById('magicDefenseAttributeAddButton')
  vitalityAttributeAddButton     = contentsPanel:getChildById('vitalityAttributeAddButton')
  willPowerAttributeAddButton    = contentsPanel:getChildById('willPowerAttributeAddButton')
  agilityAttributeAddButton      = contentsPanel:getChildById('agilityAttributeAddButton')
  dodgeAttributeAddButton        = contentsPanel:getChildById('dodgeAttributeAddButton')
  walkingAttributeAddButton      = contentsPanel:getChildById('walkingAttributeAddButton')
  luckAttributeAddButton         = contentsPanel:getChildById('luckAttributeAddButton')

  attackAttributeLabel       = contentsPanel:getChildById('attackAttributeLabel')
  defenseAttributeLabel      = contentsPanel:getChildById('defenseAttributeLabel')
  magicDefenseAttributeLabel = contentsPanel:getChildById('magicDefenseAttributeLabel')
  vitalityAttributeLabel     = contentsPanel:getChildById('vitalityAttributeLabel')
  willPowerAttributeLabel    = contentsPanel:getChildById('willPowerAttributeLabel')
  agilityAttributeLabel      = contentsPanel:getChildById('agilityAttributeLabel')
  dodgeAttributeLabel        = contentsPanel:getChildById('dodgeAttributeLabel')
  walkingAttributeLabel      = contentsPanel:getChildById('walkingAttributeLabel')
  luckAttributeLabel         = contentsPanel:getChildById('luckAttributeLabel')

  attackAttributeActLabel       = contentsPanel:getChildById('attackAttributeActLabel')
  defenseAttributeActLabel      = contentsPanel:getChildById('defenseAttributeActLabel')
  magicDefenseAttributeActLabel = contentsPanel:getChildById('magicDefenseAttributeActLabel')
  vitalityAttributeActLabel     = contentsPanel:getChildById('vitalityAttributeActLabel')
  willPowerAttributeActLabel    = contentsPanel:getChildById('willPowerAttributeActLabel')
  agilityAttributeActLabel      = contentsPanel:getChildById('agilityAttributeActLabel')
  dodgeAttributeActLabel        = contentsPanel:getChildById('dodgeAttributeActLabel')
  walkingAttributeActLabel      = contentsPanel:getChildById('walkingAttributeActLabel')
  luckAttributeActLabel         = contentsPanel:getChildById('luckAttributeActLabel')

  availablePointsLabel = attributeFooter:getChildById('availablePointsLabel')
  pointsCostLabel      = attributeFooter:getChildById('pointsCostLabel')

  attributeLabel = {
    [ATTRIBUTE_ATTACK]       = attackAttributeLabel,
    [ATTRIBUTE_DEFENSE]      = defenseAttributeLabel,
    [ATTRIBUTE_MAGICDEFENSE] = magicDefenseAttributeLabel,
    [ATTRIBUTE_VITALITY]     = vitalityAttributeLabel,
    [ATTRIBUTE_WILLPOWER]    = willPowerAttributeLabel,
    [ATTRIBUTE_AGILITY]      = agilityAttributeLabel,
    [ATTRIBUTE_DODGE]        = dodgeAttributeLabel,
    [ATTRIBUTE_WALKING]      = walkingAttributeLabel,
    [ATTRIBUTE_LUCK]         = luckAttributeLabel,
  }

  attributeActLabel = {
    [ATTRIBUTE_ATTACK]       = attackAttributeActLabel,
    [ATTRIBUTE_DEFENSE]      = defenseAttributeActLabel,
    [ATTRIBUTE_MAGICDEFENSE] = magicDefenseAttributeActLabel,
    [ATTRIBUTE_VITALITY]     = vitalityAttributeActLabel,
    [ATTRIBUTE_WILLPOWER]    = willPowerAttributeActLabel,
    [ATTRIBUTE_AGILITY]      = agilityAttributeActLabel,
    [ATTRIBUTE_DODGE]        = dodgeAttributeActLabel,
    [ATTRIBUTE_WALKING]      = walkingAttributeActLabel,
    [ATTRIBUTE_LUCK]         = luckAttributeActLabel,
  }

  attackAttributeAddButton.attributeId       = ATTRIBUTE_ATTACK
  defenseAttributeAddButton.attributeId      = ATTRIBUTE_DEFENSE
  magicDefenseAttributeAddButton.attributeId = ATTRIBUTE_MAGICDEFENSE
  vitalityAttributeAddButton.attributeId     = ATTRIBUTE_VITALITY
  willPowerAttributeAddButton.attributeId    = ATTRIBUTE_WILLPOWER
  agilityAttributeAddButton.attributeId      = ATTRIBUTE_AGILITY
  dodgeAttributeAddButton.attributeId        = ATTRIBUTE_DODGE
  walkingAttributeAddButton.attributeId      = ATTRIBUTE_WALKING
  luckAttributeAddButton.attributeId         = ATTRIBUTE_LUCK

  attackAttributeAddButton.onClick       = GameAttributes.onClickAddButton
  defenseAttributeAddButton.onClick      = GameAttributes.onClickAddButton
  magicDefenseAttributeAddButton.onClick = GameAttributes.onClickAddButton
  vitalityAttributeAddButton.onClick     = GameAttributes.onClickAddButton
  willPowerAttributeAddButton.onClick    = GameAttributes.onClickAddButton
  agilityAttributeAddButton.onClick      = GameAttributes.onClickAddButton
  dodgeAttributeAddButton.onClick        = GameAttributes.onClickAddButton
  walkingAttributeAddButton.onClick      = GameAttributes.onClickAddButton
  luckAttributeAddButton.onClick         = GameAttributes.onClickAddButton

  connect(g_game, {
    onGameStart        = GameAttributes.online,
    onGameEnd          = GameAttributes.offline,
    onPlayerAttributes = GameAttributes.onPlayerAttributes
  })

  if g_game.isOnline() then
    GameAttributes.online()
  end
end

function GameAttributes.terminate()
  disconnect(g_game, {
    onGameStart        = GameAttributes.online,
    onGameEnd          = GameAttributes.offline,
    onPlayerAttributes = GameAttributes.onPlayerAttributes
  })

  attributeTopMenuButton:destroy()
  attributeWindow:destroy()

  attributeTopMenuButton = nil
  attributeWindow        = nil
  attributeFooter        = nil

  attackAttributeAddButton       = nil
  defenseAttributeAddButton      = nil
  magicDefenseAttributeAddButton = nil
  vitalityAttributeAddButton     = nil
  willPowerAttributeAddButton    = nil
  agilityAttributeAddButton      = nil
  dodgeAttributeAddButton        = nil
  walkingAttributeAddButton      = nil
  luckAttributeAddButton         = nil

  attackAttributeLabel       = nil
  defenseAttributeLabel      = nil
  magicDefenseAttributeLabel = nil
  vitalityAttributeLabel     = nil
  willPowerAttributeLabel    = nil
  agilityAttributeLabel      = nil
  dodgeAttributeLabel        = nil
  walkingAttributeLabel      = nil
  luckAttributeLabel         = nil

  attackAttributeActLabel       = nil
  defenseAttributeActLabel      = nil
  magicDefenseAttributeActLabel = nil
  vitalityAttributeActLabel     = nil
  willPowerAttributeActLabel    = nil
  agilityAttributeActLabel      = nil
  dodgeAttributeActLabel        = nil
  walkingAttributeActLabel      = nil
  luckAttributeActLabel         = nil

  availablePointsLabel = nil
  pointsCostLabel      = nil

  g_keyboard.unbindKeyDown('Ctrl+Shift+U')

  _G.GameAttributes = nil
end

function GameAttributes.toggle()
  GameInterface.toggleMiniWindow(attributeWindow)
end

function GameAttributes.online()
  local localPlayer = g_game.getLocalPlayer()

  connect(localPlayer, {
    onVocationChange = GameAttributes.onVocationChange,
  })

  attributeWindow:setup(attributeTopMenuButton)

  GameAttributes.clearWindow()

  g_game.sendAttributeBuffer(string.format('%d', attribute_flag_updateList))
end

function GameAttributes.offline()
  local localPlayer = g_game.getLocalPlayer()

  disconnect(localPlayer, {
    onVocationChange = GameAttributes.onVocationChange,
  })
end

function GameAttributes.clearWindow()
  attackAttributeActLabel:setText(string.format('%.2f', 0))
  defenseAttributeActLabel:setText(string.format('%.2f', 0))
  magicDefenseAttributeActLabel:setText(string.format('%.2f', 0))
  vitalityAttributeActLabel:setText(string.format('%.2f', 0))
  willPowerAttributeActLabel:setText(string.format('%.2f', 0))
  agilityAttributeActLabel:setText(string.format('%.2f', 0))
  dodgeAttributeActLabel:setText(string.format('%.2f', 0))
  walkingAttributeActLabel:setText(string.format('%.2f', 0))
  luckAttributeActLabel:setText(string.format('%.2f', 0))

  availablePointsLabel:setText(string.format('Pts to use: %d', 0))
  pointsCostLabel:setText(string.format('Cost: %d', 0))

  attackAttributeActLabel:removeTooltip()
  defenseAttributeActLabel:removeTooltip()
  magicDefenseAttributeActLabel:removeTooltip()
  vitalityAttributeActLabel:removeTooltip()
  willPowerAttributeActLabel:removeTooltip()
  agilityAttributeActLabel:removeTooltip()
  dodgeAttributeActLabel:removeTooltip()
  walkingAttributeActLabel:removeTooltip()
  luckAttributeActLabel:removeTooltip()

  availablePointsLabel:setTooltip(string.format('Used points with cost: %d\nUsed points without cost: %d', 0, 0))
  pointsCostLabel:setTooltip(string.format('Points to increase cost: %d', 0))

  attackAttributeActLabel:setColor('#dfdfdf')
  defenseAttributeActLabel:setColor('#dfdfdf')
  magicDefenseAttributeActLabel:setColor('#dfdfdf')
  vitalityAttributeActLabel:setColor('#dfdfdf')
  willPowerAttributeActLabel:setColor('#dfdfdf')
  agilityAttributeActLabel:setColor('#dfdfdf')
  dodgeAttributeActLabel:setColor('#dfdfdf')
  walkingAttributeActLabel:setColor('#dfdfdf')
  luckAttributeActLabel:setColor('#dfdfdf')
end

function GameAttributes.onPlayerAttributes(tooltips, attributes, availablePoints, usedPoints, distributionPoints, pointsCost, pointsToCostIncrease)
  if not attributeLabel or not attributeActLabel then
    return
  end

  for _, attribute in ipairs(attributes) do
    local id = attribute[1]

    if attributeActLabel[id] then
      attributeActLabel[id].distributionPoints = attribute[2]
      attributeActLabel[id].alignmentPoints    = attribute[3]
      attributeActLabel[id].alignmentMaxPoints = attribute[4]
      attributeActLabel[id].buffPoints         = attribute[5]
      attributeActLabel[id].total              = attribute[6]

      attributeActLabel[id]:setText(string.format('%0.02f', attributeActLabel[id].total))
      GameAttributes.updateActLabelTooltip(id)
      attributeActLabel[id]:setColor(attributeActLabel[id].buffPoints > 0 and 'green' or attributeActLabel[id].buffPoints < 0 and 'red' or '#dfdfdf')
    end

    if attributeLabel[id] then
      if table.size(tooltips) > 1 then
        attributeLabel[id]:setTooltip(tooltips[id], TooltipType.textBlock)
      end
    end
  end

  _availablePoints = availablePoints
  availablePointsLabel:setText(string.format('Pts to use: %d', availablePoints))
  availablePointsLabel:setTooltip(string.format('Used points with cost: %d\nUsed points without cost: %d', usedPoints, distributionPoints))
  pointsCostLabel:setText(string.format('Cost: %d', pointsCost))
  pointsCostLabel:setTooltip(string.format('Points to increase cost: %d', pointsToCostIncrease))
end

function GameAttributes.sendAdd(attributeId)
  g_game.sendAttributeBuffer(string.format('%d', attributeId))
end

function GameAttributes.onClickAddButton(widget)
  if not widget.attributeId then
    return
  end

  GameAttributes.sendAdd(widget.attributeId)
end

function GameAttributes.updateActLabelTooltip(attrId)
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then
    return
  end

  local widget                 = attributeActLabel[attrId]
  local distributionPointsText = widget.distributionPoints ~= 0 and string.format('Distribution: %d\n', widget.distributionPoints) or ''
  local alignmentPointsText    = widget.alignmentPoints ~= 0 and string.format('Alignment: %.2f%s\n', widget.alignmentPoints, (attrId ~= ATTRIBUTE_VITALITY or not localPlayer or not localPlayer:isWarrior()) and string.format(' of %.2f', widget.alignmentMaxPoints) or '') or ''
  local buffPointsText         = widget.buffPoints ~= 0 and string.format('Buff/Debuff: %s%.2f\n', widget.buffPoints > 0 and '+' or '', widget.buffPoints) or ''
  local moreThanMaximum        = (widget.distributionPoints + widget.alignmentPoints + widget.buffPoints) > widget.total
  local totalPointsText        = widget.total ~= 0 and string.format('Total: %.2f%s', widget.total, moreThanMaximum and '\n(exceed the maximum value)' or '') or ''

  widget:setTooltip(string.format('%s%s%s%s', distributionPointsText, alignmentPointsText, buffPointsText, totalPointsText))
end

function GameAttributes.onVocationChange(creature, vocation, oldVocation)
  local localPlayer = g_game.getLocalPlayer()
  if creature ~= localPlayer then
    return
  end

  for attrId = ATTRIBUTE_FIRST, ATTRIBUTE_LAST do
    -- Update act label tooltip
    GameAttributes.updateActLabelTooltip(attrId)
  end
end
