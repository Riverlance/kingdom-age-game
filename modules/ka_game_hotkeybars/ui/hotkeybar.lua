UIHotkeyBar = extends(UIWidget, 'UIHotkeyBar')

local containersLimit = 10
local defaultTooltip = 'Drag hotkeys (%s), items or powers (%s) to this bar.'
local hotkeyManagerKeyCombo = 'Ctrl+K'
local powerListKeyCombo = 'Ctrl+Shift+P'
local allowedDrops = {'UIHotkeyLabel', 'UIHotkeyBarContainer', 'UIPowerButton', 'UIItem', 'UIGameMap'}

local BGColors = {
  Open        = '#00000077',
  Closed      = '#00000000',
  Highlighted = '#ffffff77'
}

function UIHotkeyBar.create()
  local obj = UIHotkeyBar.internalCreate()
  obj:setId('hotkeybar_none')
  obj.hotkeyList = { }
  obj:setTooltip(tr(defaultTooltip, hotkeyManagerKeyCombo, powerListKeyCombo))
  return obj
end

function UIHotkeyBar:onSetup()
  self.visibilityButton = self:getChildById('visibilityButton')
  self.onClick = function() if not self.visibilityButton:isOn() then self:toggle() end end
  self.visibilityButton.onClick = function() self:toggle() end
  self.visibilityButton.onHoverChange = function(button, hovered)
      UIWidget.onHoverChange(button, hovered)
      button:setOpacity(hovered and 1 or 0)
    end
end

function UIHotkeyBar:unload()
  self:resetTempContainer()
  self:getHotkeyList():destroyChildren()
  self.hotkeyList = { }
end

function UIHotkeyBar:load(settings)
  local settings = settings or { }
  if settings.visible == nil then
    settings.visible = true
  end

  self:setup(settings.visible)
  settings.visible = nil
  local hotkeyList = {}
  --preload
  for index, keyCombo in pairs(settings) do
    hotkeyList[tonumber(index)] = tostring(keyCombo)
  end
  --create widgets
  local index = 1
  for _, keyCombo in ipairs(hotkeyList) do
    local keySettings = GameHotkeys.getHotkey(keyCombo)
    if keySettings then
      self:addHotkey(index, keySettings)
      index = index + 1
    else
      print("Hotkey '" .. keyCombo .. "' does not exist.")
    end
  end
end

function UIHotkeyBar:getHotkeyList()
  return self:getChildById('hotkeyList')
end

function UIHotkeyBar:setup(visible)
  local highlighted = self:isOn()
  local bg = not visible and BGColors.Closed or highlighted and BGColors.Highlighted or BGColors.Open
  self:setBackgroundColor(bg)
  self:getHotkeyList():setVisible(visible)
  self.visibilityButton:setOn(visible)
  self.visibilityButton:setTooltip(visible and 'Hide' or 'Show')
end

function UIHotkeyBar:toggle()
  self:setup(not self.visibilityButton:isOn())
end

function UIHotkeyBar:setHighlight(highlight)
  self:setOn(highlight)
  local open = self.visibilityButton:isOn()
  self:setup(highlight or not self.autoClose)
  self.autoClose = highlight and not open or nil
  for _, hotkey in ipairs(self:getHotkeyList():getChildren()) do
    hotkey:getChildById('deleteButton'):setVisible(highlight)
  end
end

function UIHotkeyBar:getIndexByPos(mousePos)
  local isVertical   = self:getStyleName() == 'HotkeyBarVertical'
  local isHorizontal = self:getStyleName() == 'HotkeyBarHorizontal'
  local hotkeyWidgets = self:getHotkeyList():getChildren()
  local index = 1
  for i, w in ipairs(hotkeyWidgets) do
    if isVertical and mousePos.y <= w:getY() + math.floor(w:getHeight() / 2) then
      index = i
      break
    elseif isHorizontal and mousePos.x <= w:getX() + math.floor(w:getWidth() / 2) then
      index = i
      break
    end
    index = i + 1
  end
  return index
end

function UIHotkeyBar:addHotkeyButton(index, hotkeyWidget)
  self:getHotkeyList():insertChild(index, hotkeyWidget)
  hotkeyWidget:getChildById('deleteButton'):setVisible(self:isOn())
end

function UIHotkeyBar:addHotkey(index, keySettings)
  if #self.hotkeyList >= containersLimit then
    return
  end

  if keySettings and keySettings.keyCombo and self.hotkeyList[keySettings.keyCombo] then
    return
  end

  local hotkeyWidget = g_ui.createWidget('HotkeyBarContainer')
  hotkeyWidget.index = index
  hotkeyWidget:setOpacity(0.5)
  hotkeyWidget.settings = keySettings
  self:addHotkeyButton(index, hotkeyWidget)
  hotkeyWidget:updateLook()

  if not keySettings.keyCombo then
    self.tempContainer = hotkeyWidget
    self.tempContainer:setId('temp')
  else
    self:onAssignHotkey(keySettings, true, hotkeyWidget)
  end

end

function UIHotkeyBar:onAssignHotkey(keySettings, applied, hotkeyWidget)
  if not keySettings then
    print("Error: no keySettings!")
    return
  end
  if not hotkeyWidget then
    hotkeyWidget = self.tempContainer
    hotkeyWidget.locked = false
  end
  if hotkeyWidget then
    if applied then
      local keyCombo = keySettings.keyCombo
      --remove existing container of same keyCombo to prioritize the new position
      local existingContainer = self.hotkeyList[keyCombo]
      if existingContainer then
        existingContainer:destroy()
      end

      hotkeyWidget:setId(keyCombo)
      hotkeyWidget:setOpacity(1)
      local callback = function()
          if GameHotkeys.isOpen() then return end
          GameHotkeys.doKeyCombo(keyCombo, hotkeyWidget)
        end
      if tonumber(keySettings.powerId) then
        hotkeyWidget.onMousePress = callback
      else
        hotkeyWidget.onMouseRelease = callback
      end
      self.hotkeyList[keyCombo] = hotkeyWidget
      hotkeyWidget:updateLook()
      self.tempContainer = nil
    elseif self.tempContainer then
      self.tempContainer.locked = false
      self:resetTempContainer()
    end
  end
end


function UIHotkeyBar:configHotkey(widget)
  local keySettings = {}
  local widgetClass = widget:getClassName()
  if widgetClass == 'UIPowerButton' then
    keySettings.powerId = widget.power.id
  elseif widgetClass == 'UIItem' then
    keySettings.itemId = widget:getItemId()
    keySettings.subType = widget:getItemSubType()
    if widget:getItem():isMultiUse() then
      keySettings.useType = HotkeyItemUseType.Crosshair
    end
  elseif widgetClass == 'UIGameMap' then
    local item = widget.currentDragThing
    if item:isPickupable() then
      keySettings.itemId = item:getId()
      keySettings.subType = item:getSubType()
      if item:isMultiUse() then
        keySettings.useType = HotkeyItemUseType.Crosshair
      end
    end
  elseif widgetClass == 'UIHotkeyLabel' then
    keySettings = widget.settings
  end
  keySettings.hotkeyBarId = self.id
  return keySettings
end


function UIHotkeyBar:removeHotkey(keyCombo)
  if self.hotkeyList[keyCombo] then
    self.hotkeyList[keyCombo]:destroy()
    self.hotkeyList[keyCombo] = nil
  end
end

function UIHotkeyBar:resetTempContainer()
   if self.tempContainer and not self.tempContainer.locked then
    self.tempContainer:destroy()
    self.tempContainer = nil
  end
end

--mouse events

function UIHotkeyBar:onHoverChange(hovered)
  local mousePos = g_window.getMousePosition()
  self.visibilityButton:setOpacity(hovered and 1 or 0)
  self:updateHoveredWidget(mousePos)
  if not hovered then
    self:resetTempContainer()
    return
  end
  local draggingWidget = g_ui.getDraggingWidget()
  if not draggingWidget then
    self:resetTempContainer()
    return
  end
  if not self:canAcceptDrop(draggingWidget) then
    return
  end
  if self.tempContainer then
    return
  end
  local index = self:getIndexByPos(mousePos)
  local widgetClass = draggingWidget:getClassName()
  if widgetClass == 'UIHotkeyBarContainer' then
    draggingWidget:setOpacity(0.5)
    self:addHotkeyButton(index, draggingWidget)
    return
  elseif widgetClass == 'UIGameMap' then
    if not draggingWidget.currentDragThing:isPickupable() then
      return
    end
  end
  local keySettings = self:configHotkey(draggingWidget)
  self:addHotkey(index, keySettings)
end

function UIHotkeyBar:onMouseMove(mousePos, mouseMoved)
  if not self:isHovered() then
    self:resetTempContainer()
    return
  end

  local draggingWidget = g_ui.getDraggingWidget()
  if draggingWidget then --only drag and drop
    if self.tempContainer and not self.tempContainer.locked then
      local parent =  self.tempContainer:getParent()
      local index =  self:getIndexByPos(mousePos)
      if index <= parent:getChildCount() then
        parent:moveChildToIndex(self.tempContainer, index)
      end
    end
    return
  end
  self:resetTempContainer()
  self:updateHoveredWidget(mousePos)
end

function UIHotkeyBar:updateHoveredWidget(mousePos, hovered)
  local hoveredWidget = self:getHotkeyList():isVisible() and self:getHotkeyList():getChildByPos(mousePos) or self:getChildByPos(mousePos) or self:containsPoint(mousePos) and self or nil
  if self.hoveredWidget ~= hoveredWidget then
    if self.hoveredWidget then
      UIWidget.onHoverChange(self.hoveredWidget, false)
    end
    self.hoveredWidget = hoveredWidget
    if hoveredWidget then
      UIWidget.onHoverChange(hoveredWidget, true)
    end
  end
end

function UIHotkeyBar:onDrop(widget, mousePos)
  if not self:canAcceptDrop(widget) then
    return false
  end
  local index = self:getIndexByPos(mousePos)
  local widgetClass = widget:getClassName()
  if widgetClass == 'UIHotkeyBarContainer' then
    widget:getParentBar():removeHotkey(widget.keyCombo)
    self:addHotkey(index, widget.settings)
  elseif self.tempContainer then
    self.tempContainer.locked = true
    GameHotkeys.assignHotkey(self.tempContainer.settings)
  end
  return true
end

function UIHotkeyBar:canAcceptDrop(widget)
  if not widget then
    return false
  end
  if not self.visibilityButton:isOn() then
    return false
  end
  if not table.contains(allowedDrops, widget:getClassName()) then
    return false
  end
  if self.tempContainer and self.tempContainer.locked then
    return false
  end
  return true
end

--update functions

function UIHotkeyBar:updateLook(keyCombo)
  if keyCombo and self.hotkeyList[keyCombo] then
    self.hotkeyList[keyCombo]:updateLook()
    return
  end
  local children = self:getHotkeyList():getChildren()
  for _, widget in ipairs(children) do
    if widget:getClassName() == 'UIHotkeyBarContainer' then
      widget:updateLook()
    end
  end
end

function UIHotkeyBar:updateDraggable(draggable)
  local children = self:getHotkeyList():getChildren()
  for _, widget in ipairs(children) do
    if widget:getClassName() == 'UIHotkeyBarContainer' then
      widget:setDraggable(draggable)
    end
  end
end
