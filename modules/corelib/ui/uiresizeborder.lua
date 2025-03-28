-- @docclass
UIResizeBorder = extends(UIWidget, 'UIResizeBorder')

function UIResizeBorder.create()
  local resizeborder = UIResizeBorder.internalCreate()
  resizeborder:setFocusable(false)
  resizeborder.minimum = 0
  resizeborder.maximum = 10000
  resizeborder.invert = false
  return resizeborder
end

function UIResizeBorder:onSetup()
  if self:getWidth() > self:getHeight() then
    self.vertical = true
  else
    self.vertical = false
  end
end

function UIResizeBorder:onDestroy()
  if self.hovering then
    g_mouse.popCursor(self.cursortype)
  end
end

function UIResizeBorder:onHoverChange(hovered)
  local parent = self:getParent()

  if hovered then
    if g_mouse.isCursorChanged() or g_mouse.isPressed() or parent:getClassName() == 'UIMiniWindow' and parent:isLocked() then
      return
    end

    if self:getWidth() > self:getHeight() then
      self.vertical = true
      self.cursortype = 'vertical'
    else
      self.vertical = false
      self.cursortype = 'horizontal'
    end
    g_mouse.pushCursor(self.cursortype)
    self.hovering = true
    if not self:isPressed() then
      g_effects.fadeIn(self, 75)
    end

  else
    if not self:isPressed() and self.hovering then
      g_mouse.popCursor(self.cursortype)
      g_effects.fadeOut(self, 150)
      self.hovering = false
    end
  end
end

function UIResizeBorder:onMouseMove(mousePos, mouseMoved)
  if not self:isPressed() then
    return false
  end

  local parent = self:getParent()
  if parent:getClassName() == 'UIMiniWindow' and parent:isLocked() then
    return false
  end

  local newSize = 0

  if self.vertical then
    local delta = mousePos.y - self:getY() - math.floor(self:getHeight()/2)
    if delta == 0 then
      return false
    end
    if self.invert then
      delta = -delta
    end
    newSize = math.min(math.max(parent:getHeight() + delta, self.minimum), self.maximum)
    parent:setHeight(newSize)

  else
    local delta = mousePos.x - self:getX() - math.floor(self:getWidth()/2)
    if delta == 0 then
      return false
    end
    if self.invert then
      delta = -delta
    end
    newSize = math.min(math.max(parent:getWidth() + delta, self.minimum), self.maximum)
    parent:setWidth(newSize)
  end

  self:checkBoundary(newSize)

  return true
end

function UIResizeBorder:onMouseRelease(mousePos, mouseButton)
  if not self:isHovered() then
    g_mouse.popCursor(self.cursortype)
    g_effects.fadeOut(self, 150)
    self.hovering = false
  end
end

function UIResizeBorder:onStyleApply(styleName, styleNode)
  for name, value in pairs(styleNode) do
    if name == 'maximum' then
      self:setMaximum(tonumber(value))
    elseif name == 'minimum' then
      self:setMinimum(tonumber(value))
    elseif name == 'invert' then
      self.invert = value
    end
  end
end

function UIResizeBorder:onVisibilityChange(visible)
  if visible and self.maximum == self.minimum then
    self:hide()
  end
end

function UIResizeBorder:onDoubleClick(mousePosition)
  local parent = self:getParent()
  if parent:getClassName() == 'UIMiniWindow' and parent:isLocked() then
    return
  end

  self:setParentSize(self.minimum)
end

function UIResizeBorder:setMaximum(maximum)
  self.maximum = maximum
  self:checkBoundary()
end

function UIResizeBorder:setMinimum(minimum)
  self.minimum = minimum
  self:checkBoundary()
end

function UIResizeBorder:getMaximum()
  return self.maximum
end

function UIResizeBorder:getMinimum()
  return self.minimum
end

function UIResizeBorder:setParentSize(size)
  local parent = self:getParent()
  if self.vertical then
    parent:setHeight(size)
  else
    parent:setWidth(size)
  end
  self:checkBoundary(size)
end

function UIResizeBorder:getParentSize()
  local parent = self:getParent()
  if self.vertical then
    return parent:getHeight()
  else
    return parent:getWidth()
  end
end

function UIResizeBorder:checkBoundary(size)
  size = size or self:getParentSize()
  if self.maximum == self.minimum and size == self.maximum then
    self:hide()
  else
    self:show()
  end
end
