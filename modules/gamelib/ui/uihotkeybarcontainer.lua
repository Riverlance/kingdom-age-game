UIHotkeyBarContainer = extends(UIWidget, 'UIHotkeyBarContainer')

function UIHotkeyBarContainer:onDragEnter(mousePos)
  self:setBorderWidth(1)
  g_mouse.pushCursor('target')
  return true
end

function UIHotkeyBarContainer:onDragLeave(droppedWidget, mousePos)
  g_mouse.popCursor('target')
  self:setBorderWidth(0)
  return true
end

function UIHotkeyBarContainer:getParentBar()
  return self:getParent():getParent()
end

function UIHotkeyBarContainer:updateLook()
  local keySettings = self.settings
  if not keySettings then
    g_logger.error(tr('[UIHotkeyBarContainer.updateLook] missing field `settings` (%s)', self:getId()))
    return
  end

  --reset look
  local hasTooltip = true
  local tooltipText = ''
  self:setText('')
  local itemWidget = self:getChildById('item')
  itemWidget:setVisible(false)
  local powerWidget = self:getChildById('power')
  powerWidget:setVisible(false)

  --update look
  if string.exists(keySettings.keyCombo) then
    tooltipText = tr('[%s]', keySettings.keyCombo)
  else
    hasTooltip = false
  end

  if string.exists(keySettings.text) then
    self:setText('(...)')
    tooltipText = tr('%s Send message%s:\n%s', tooltipText, keySettings.autoSend and ' (auto)' or '', keySettings.text)
  elseif keySettings.powerId and powerWidget then
    powerWidget:setVisible(true)
    powerWidget:setImageSource('/images/ui/power/' .. keySettings.powerId .. '_off')

    local power = GamePowers.getPowerInfo(keySettings.powerId)
    if power and power.name and power.level then
      tooltipText = tr('%s %s (level %d)', tooltipText, power.name, power.level)
    end
  elseif keySettings.itemId and itemWidget then
    itemWidget:setVisible(true)
    itemWidget:setItemId(keySettings.itemId)
    itemWidget:setItemSubType(keySettings.subType)
    if keySettings.useType == HotkeyItemUseType.Default then
      tooltipText = tr('%s Use item', tooltipText)
    elseif keySettings.useType == HotkeyItemUseType.Self then
      tooltipText = tr('%s Use on yourself', tooltipText)
    elseif keySettings.useType == HotkeyItemUseType.Target then
      tooltipText = tr('%s Use on target', tooltipText)
    elseif keySettings.useType == HotkeyItemUseType.Crosshair then
      tooltipText = tr('%s Use with', tooltipText)
    end
  end
  self:setTooltip(hasTooltip and tooltipText or '')
end
