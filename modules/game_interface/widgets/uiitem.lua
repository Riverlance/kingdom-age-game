function UIItem:onSetup()
  self:updateBackground()
end

function UIItem:onDragEnter(mousePos)
  if self:isVirtual() then
    return false
  end

  local item = self:getItem()
  if not item then
    return false
  end

  self:setBorderWidth(1)
  self.currentDragThing = item
  g_mouse.pushCursor('target')
  g_mouseicon.displayItem(item)
  return true
end

function UIItem:onDragLeave(droppedWidget, mousePos)
  if self:isVirtual() then
    return false
  end
  self.currentDragThing = nil
  g_mouseicon.hide()
  g_mouse.popCursor('target')
  self:setBorderWidth(0)
  if self.hoveredWho then
    self.hoveredWho:setBorderWidth(0)
  end
  self.hoveredWho = nil
  return true
end

function UIItem:onDrop(widget, mousePos)
  self:setBorderWidth(0)

  if not self:canAcceptDrop(widget, mousePos) then
    return false
  end

  local item = widget.currentDragThing
  if not item:isItem() then
    return false
  end

  local itemPos = item:getPosition()
  local itemTile = item:getTile()
  if itemPos.x ~= 65535 and not itemTile then
    return false
  end

  local toPos = self.position
  if itemPos.x == toPos.x and itemPos.y == toPos.y and itemPos.z == toPos.z then
    return false
  end

  if item:getCount() > 1 then
    GameInterface.moveStackableItem(item, toPos)
  else
    g_game.move(item, toPos, 1)
  end

  return true
end

function UIItem:onDestroy()
  if self == g_ui.getDraggingWidget() and self.hoveredWho then
    self.hoveredWho:setBorderWidth(0)
  end

  if self.hoveredWho then
    self.hoveredWho = nil
  end
end

function UIItem:onHoverChange(hovered)
  UIWidget.onHoverChange(self, hovered)

  if self:isVirtual() or not self:isDraggable() then
    return
  end

  local draggingWidget = g_ui.getDraggingWidget()
  if draggingWidget and self ~= draggingWidget then
    local gotMap = draggingWidget:getClassName() == 'UIGameMap'
    local gotItem = draggingWidget:getClassName() == 'UIItem' and not draggingWidget:isVirtual()
    if hovered and (gotItem or gotMap) then
      self:setBorderWidth(1)
      draggingWidget.hoveredWho = self
    else
      self:setBorderWidth(0)
      draggingWidget.hoveredWho = nil
    end
  end
end

function UIItem:onMouseRelease(mousePosition, mouseButton)
  if self.cancelNextRelease then
    self.cancelNextRelease = false
    return true
  end

  if self:isVirtual() then
    return false
  end

  local item = self:getItem()
  if not item or not self:containsPoint(mousePosition) then
    return false
  end

  if --[[ClientOptions.getOption('classicControl') and]]
     ((g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton) or
      (g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton)) then
    self.cancelNextRelease = true
    if GameInterface.processMouseAction(mousePosition, mouseButton, nil, item, item, item) then
      return true
    end
    return false
  elseif GameInterface.processMouseAction(mousePosition, mouseButton, nil, item, item, item) then
    return true
  elseif g_ui.isMouseGrabbed() then -- For double click of item 'use with' work
    return true
  end
  return false
end

function UIItem:onDoubleClick(mousePosition)
  if self.cancelNextRelease then
    self.cancelNextRelease = false
    return true
  end

  local item = self:getItem()
  if not item or not self:containsPoint(mousePosition) then
    return false
  end

  if g_keyboard.getModifiers() == KeyboardNoModifier then
    g_game.look(item)
  end
  return true
end

function UIItem:canAcceptDrop(widget, mousePos)
  if self:isVirtual() or not self:isDraggable() then
    return false
  end

  if not widget or not widget.currentDragThing then
    return false
  end

  local children = rootWidget:recursiveGetChildrenByPos(mousePos)
  for i = 1, #children do
    local child = children[i]
    if child == self then
      return true
    elseif not child:isPhantom() then
      return false
    end
  end

  error(f('Widget %s not in drop list.', self:getId()))
  return false
end

function UIItem:updateBackground()
  local item      = self:getItem()
  local itemClass = item and item:getClass() or 0
  local duration  = item and item:getDurability() or nil

  self:setOn(item and item:hasHighlight())

  -- Broken state
  if duration == 0 then
    self:setImageClip(torect('0 34 34 34'))

  else
    -- Class state
    self:setImageClip(torect(itemClass * 34 .. ' 0 34 34'))
  end
end
