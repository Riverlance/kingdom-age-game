-- @docclass
UIMiniWindow = extends(UIWindow, 'UIMiniWindow')

function UIMiniWindow.create()
  local miniwindow = UIMiniWindow.internalCreate()
  miniwindow.minimizedHeight = 32
  return miniwindow
end

function UIMiniWindow:open(dontSave)
  local firstTimeOpened = self:getSettings(true)
  if not firstTimeOpened and self:isExplicitlyVisible() then -- Not opened for the first time and is explicitly visible
    return
  end

  self:setVisible(true)
  if self.topMenuButton then
    self.topMenuButton:setOn(true)
  end

  if not dontSave then
    self:setSettings({closed = false})
  end

  signalcall(self.onOpen, self)
end

function UIMiniWindow:close(dontSave)
  if not self:isExplicitlyVisible() then
    return
  end

  self:setVisible(false)
  if self.topMenuButton then
    self.topMenuButton:setOn(false)
  end

  if not dontSave then
    self:setSettings({closed = true})
  end

  signalcall(self.onClose, self)
end

function UIMiniWindow:minimize(dontSave, ignoreHeightChangeSignal)
  local widget
  self:setOn(true)
  self:getChildById('contentsPanel'):hide()
  widget = self:getChildById('miniWindowHeader')
  if widget then
    widget:hide()
  end
  widget = self:getChildById('miniWindowFooter')
  if widget then
    widget:hide()
  end
  self:getChildById('miniwindowScrollBar'):hide()
  self:getChildById('bottomResizeBorder'):hide()
  self:getChildById('minimizeButton'):setOn(true)

  self:setHeight(self.minimizedHeight, true, ignoreHeightChangeSignal)

  if not dontSave then
    self:setSettings({ minimized = true })
  end

  signalcall(self.onMinimize, self)
end

function UIMiniWindow:maximize(dontSave, ignoreHeightChangeSignal)
  local widget
  self:setOn(false)
  self:getChildById('contentsPanel'):show()
  widget = self:getChildById('miniWindowHeader')
  if widget then
    widget:show()
  end
  widget = self:getChildById('miniWindowFooter')
  if widget then
    widget:show()
  end
  self:getChildById('miniwindowScrollBar'):show()
  self:getChildById('bottomResizeBorder'):show()
  self:getChildById('minimizeButton'):setOn(false)

  local height = not self:isResizeable() and self.defaultHeight or self:getSettings('height') or self:getMinimumHeight()
  self:setHeight(self:isResizeable() and math.max(height, self:getMinimumHeight()) or height, false, ignoreHeightChangeSignal)

  if not dontSave then
    self:setSettings({ minimized = false })
  end

  local parent = self:getParent()
  if parent and parent:getClassName() == 'UIMiniWindowContainer' then
    signalcall(parent.onFitAll, parent, self)
  end

  signalcall(self.onMaximize, self)
end

function UIMiniWindow:lock(dontSave)
  self:getChildById('lockButton'):setOn(true)

  if not dontSave then
    self:setSettings({locked = true})
  end

  signalcall(self.onLock, self)
end

function UIMiniWindow:unlock(dontSave)
  self:getChildById('lockButton'):setOn(false)

  if not dontSave then
    self:setSettings({locked = false})
  end

  signalcall(self.onUnlock, self)
end

function UIMiniWindow:isLocked()
  return self:getChildById('lockButton'):isOn()
end

function UIMiniWindow:setup(button)
  self:getChildById('closeButton').onClick =
    function()
      if self:isLocked() then
        return
      end

      self:close()
    end

  local minimizeButton = self:getChildById('minimizeButton')
  minimizeButton.onClick = function()
    if self:isLocked() then
      return
    end

    if self:isOn() then
      self:maximize()
    else
      self:minimize()
    end
  end

  self:getChildById('lockButton').onClick = function()
    if self:isLocked() then
      self:unlock()
    else
      self:lock()
    end
  end

  self:getChildById('miniwindowTopBar').onDoubleClick = function()
    minimizeButton.onClick()

    g_sounds.getChannel(AudioChannels.Gui):play(f('%s/button_1.ogg', getAudioChannelPath(AudioChannels.Gui)), 1.)
  end

  if button then
    self.topMenuButton = button
  end

  self.defaultHeight = self.defaultHeight or 140 -- (see ResizeBorder on 30-miniwindow for the 140 value)

  local isResizeable = self:isResizeable()
  local selfSettings = self:getSettings(true)
  local isMinimized  = selfSettings and selfSettings.minimized or self:isOn()

  if selfSettings then
    if selfSettings.parentId then
      local parent = rootWidget:recursiveGetChildById(selfSettings.parentId)
      if parent then
        if parent:getClassName() == 'UIMiniWindowContainer' and selfSettings.index then
          self.miniIndex = selfSettings.index
          parent:scheduleInsert(self, selfSettings.index)
        elseif selfSettings.position then
          self:setParent(parent, true)
          self:setPosition(topoint(selfSettings.position))
        end
      end
    end

    if isMinimized then
      self:minimize(true)
    else
      if isResizeable then
        self:setHeight(selfSettings.height or self:getMinimumHeight(), true)
      else
        self:setHeight(self.defaultHeight, true)
        -- self:eraseSettings({height = true})
      end
    end

    if selfSettings.locked then
      self:lock(true)
    else
      self:unlock(true)
    end

    if selfSettings.closed then
      self:close(true)
    else
      self:open(true)
    end
  else
    if isMinimized then
      self:minimize(true)
    else
      self:setHeight(isResizeable and self:getMinimumHeight() or self.defaultHeight, true)
    end
  end

  local oldParent = self:getParent()
  local newParent = self:getParent()

  self.miniLoaded = true

  if self.save then
    if oldParent and oldParent:getClassName() == 'UIMiniWindowContainer' then
      addEvent(function() oldParent:order() end)
    end
    if newParent and newParent:getClassName() == 'UIMiniWindowContainer' and newParent ~= oldParent then
      addEvent(function() newParent:order() end)
    end
  end

  if self.contentMinimumHeight then
    self:setContentMinimumHeight(self.contentMinimumHeight)
  end

  if self.contentMaximumHeight then
    self:setContentMaximumHeight(self.contentMaximumHeight)
  end

  self:fitOnParent()
end

function UIMiniWindow:onVisibilityChange(visible)
  self:fitOnParent()
end

function UIMiniWindow:onDragEnter(mousePos)
  local parent = self:getParent()
  if not parent or self:isLocked() then
    return false
  end

  if parent:getClassName() == 'UIMiniWindowContainer' then
    -- Save last panel on miniwindow
    self.lastPanel = parent

    local containerParent = rootWidget
    parent:removeChild(self)
    containerParent:addChild(self)
    parent:saveChildren()
  end

  local oldPos = self:getPosition()
  self.movingReference = { x = mousePos.x - oldPos.x, y = mousePos.y - oldPos.y }
  self:setPosition(oldPos)
  self.free = true
  return true
end

function UIMiniWindow:onDragLeave(droppedWidget, mousePos)
  if droppedWidget and droppedWidget:getClassName() ~= 'UIMiniWindowContainer' then
    return false
  end

  if self:getParent() == rootWidget and self.lastPanel then
    if self.movedWidget then
      local index = self.lastPanel:getChildIndex(self.movedWidget)
      self.lastPanel:insertChild(index + self.movedIndex, self)
    else
      self.lastPanel:addChild(self)
    end
    signalcall(self.lastPanel.onFitAll, self.lastPanel, self)
  end

  if self.movedWidget then
    self.setMovedChildMargin(self.movedOldMargin or 0)
    self.movedWidget = nil
    self.setMovedChildMargin = nil
    self.movedOldMargin = nil
    self.movedIndex = nil
  end

  local newParent = self:getParent()
  self:saveParent(newParent)

  if newParent ~= self.lastPanel then
    signalcall(self.onChangeWindowPanel, self, newParent)
  end

  return true
end

function UIMiniWindow:onDragMove(mousePos, mouseMoved)
  local oldMousePosY = mousePos.y - mouseMoved.y
  local children = rootWidget:recursiveGetChildrenByMarginPos(mousePos)
  local overAnyWidget = false
  for i=1,#children do
    local child = children[i]
    if child:getParent():getClassName() == 'UIMiniWindowContainer' then
      overAnyWidget = true

      local childCenterY = child:getY() + child:getHeight() / 2
      if child == self.movedWidget and mousePos.y < childCenterY and oldMousePosY < childCenterY then
        break
      end

      if self.movedWidget then
        self.setMovedChildMargin(self.movedOldMargin or 0)
        self.setMovedChildMargin = nil
      end

      if mousePos.y < childCenterY then
        self.movedOldMargin = child:getMarginTop()
        self.setMovedChildMargin = function(v) child:setMarginTop(v) end
        self.movedIndex = 0
      else
        self.movedOldMargin = child:getMarginBottom()
        self.setMovedChildMargin = function(v) child:setMarginBottom(v) end
        self.movedIndex = 1
      end

      self.movedWidget = child
      self.setMovedChildMargin(self:getHeight())
      break
    end
  end

  if not overAnyWidget and self.movedWidget then
    self.setMovedChildMargin(self.movedOldMargin or 0)
    self.movedWidget = nil
  end

  return UIWindow.onDragMove(self, mousePos, mouseMoved)
end

function UIMiniWindow:onMousePress()
  local parent = self:getParent()
  if not parent or self:isLocked() then
    return false
  end

  if parent:getClassName() ~= 'UIMiniWindowContainer' then
    self:raise()
    return true
  end
end

function UIMiniWindow:onFocusChange(focused)
  if not focused then
    return
  end

  local parent = self:getParent()
  if parent and parent:getClassName() ~= 'UIMiniWindowContainer' then
    self:raise()
  end
end

function UIMiniWindow:onHeightChange(height)
  if not self:isOn() then
    self:setSettings({height = height})
  end
  self:fitOnParent()
end

function UIMiniWindow:getSettings(name)
  if not self.save then
    return nil
  end

  local playerSettings = Client.getPlayerSettings()
  local settings = playerSettings:getNode('MiniWindows')

  if settings then
    local selfSettings = settings[self:getId()]
    if selfSettings then
      return name == true and selfSettings or selfSettings[name]
    end
  end

  return nil
end

function UIMiniWindow:setSettings(data)
  if not self.save then
    return
  end

  local playerSettings = Client.getPlayerSettings()
  local settings = playerSettings:getNode('MiniWindows') or { }

  local id = self:getId()
  if not settings[id] then
    settings[id] = { }
  end

  for key,value in pairs(data) do
    settings[id][key] = value
  end

  playerSettings:setNode('MiniWindows', settings)
  playerSettings:save()
end

function UIMiniWindow:eraseSettings(data)
  if not self.save then
    return
  end

  local playerSettings = Client.getPlayerSettings()
  local settings = playerSettings:getNode('MiniWindows') or { }

  local id = self:getId()
  if not settings[id] then
    settings[id] = { }
  end

  for key,value in pairs(data) do
    settings[id][key] = nil
  end

  playerSettings:setNode('MiniWindows', settings)
  playerSettings:save()
end

function UIMiniWindow:saveParent(parent)
  local parent = self:getParent()
  if parent then
    if parent:getClassName() == 'UIMiniWindowContainer' then
      parent:saveChildren()
    else
      self:saveParentPosition(parent:getId(), self:getPosition())
    end
  end
end

function UIMiniWindow:saveParentPosition(parentId, position)
  local selfSettings = { }
  selfSettings.parentId = parentId
  selfSettings.position = pointtostring(position)
  self:setSettings(selfSettings)
end

function UIMiniWindow:saveParentIndex(parentId, index)
  local selfSettings = { }
  selfSettings.parentId = parentId
  selfSettings.index = index
  self:setSettings(selfSettings)
  self.miniIndex = index
end

function UIMiniWindow:disableResize()
  self:getChildById('bottomResizeBorder'):disable()
end

function UIMiniWindow:enableResize()
  self:getChildById('bottomResizeBorder'):enable()
end

function UIMiniWindow:fitOnParent()
  local parent = self:getParent()
  if self:isVisible() and parent and parent:getClassName() == 'UIMiniWindowContainer' then
    signalcall(parent.onFitAll, parent, self)
  end
end

function UIMiniWindow:setParent(parent, dontsave)
  UIWidget.setParent(self, parent)
  if not dontsave then
    self:saveParent(parent)
  end
  self:fitOnParent()
end

-- Minimum window height not chosen by user
function UIMiniWindow:getRealMinHeight()
  local contentsPanel      = self:getChildById('contentsPanel')
  local miniwindowTopBar   = self:getChildById('miniwindowTopBar')
  local bottomResizeBorder = self:getChildById('bottomResizeBorder')
  local miniWindowHeader   = self:getChildById('miniWindowHeader')
  local miniWindowFooter   = self:getChildById('miniWindowFooter')

  local realMinHeight = contentsPanel:getVerticalLength() - contentsPanel:getHeight()
  realMinHeight       = realMinHeight + miniwindowTopBar:getVerticalLength(true)
  realMinHeight       = realMinHeight + bottomResizeBorder:getVerticalLength(true)
  realMinHeight       = realMinHeight + (miniWindowHeader and miniWindowHeader:getVerticalLength(true) or 0)
  realMinHeight       = realMinHeight + (miniWindowFooter and miniWindowFooter:getVerticalLength(true) or 0)

  return realMinHeight
end

function UIMiniWindow:setHeight(height, force, ignoreHeightChangeSignal)
  if not force and (height < self:getMinimumHeight() or height > self:getMaximumHeight()) then
    return
  end

  UIWidget.setHeight(self, height)
  if not ignoreHeightChangeSignal then
    signalcall(self.onHeightChange, self, height)
  end
end

function UIMiniWindow:setMinimumHeight(height)
  self:getChildById('bottomResizeBorder'):setMinimum(height)
end

function UIMiniWindow:setMaximumHeight(height)
  self:getChildById('bottomResizeBorder'):setMaximum(height)
end

function UIMiniWindow:setContentHeight(height)
  self:getChildById('bottomResizeBorder'):setParentSize(self:getRealMinHeight() + height)
end

function UIMiniWindow:setContentMinimumHeight(height)
  self:getChildById('bottomResizeBorder'):setMinimum(self:getRealMinHeight() + height)
end

function UIMiniWindow:setContentMaximumHeight(height)
  self:getChildById('bottomResizeBorder'):setMaximum(self:getRealMinHeight() + height)
end

function UIMiniWindow:getContentHeight()
  return math.max(0, self:getHeight() - self:getRealMinHeight())
end

function UIMiniWindow:getMinimumHeight()
  return math.min(self.defaultHeight, self:getChildById('bottomResizeBorder'):getMinimum())
end

function UIMiniWindow:getMaximumHeight()
  return self:getChildById('bottomResizeBorder'):getMaximum()
end

function UIMiniWindow:isResizeable()
  local bottomResizeBorder = self:getChildById('bottomResizeBorder')
  return bottomResizeBorder:isExplicitlyVisible() and bottomResizeBorder:isEnabled()
end

function UIMiniWindow:setScrollBarAutoHiding(enabled)
  local scrollbar = self:getChildById('miniwindowScrollBar')

  local data = { }
  if enabled then
    data.width = 0
  end

  scrollbar:mergeStyle({ ['$!on'] = data })
end
