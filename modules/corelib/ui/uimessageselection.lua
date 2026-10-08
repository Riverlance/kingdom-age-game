-- @docclass
-- Shared selection behavior for containers made of independent UITextEdit messages.

UITextMessageSelection = { }

local function getMessageIndex(container, message)
  return container:getChildIndex(message)
end

local function getTextLength(message)
  -- Selection positions are offsets in the source text. The displayed text
  -- may contain layout-only wrapping and must not be used for this range.
  return #message:getText()
end

local updateSelectionText

local function setMessageSelection(container, message, start, finish)
  message:setSelection(start, finish)

  local index = getMessageIndex(container, message)
  if index > 0 then
    container.selectionRanges[index] = {
      start = message:getSelectionStart(),
      finish = message:getSelectionEnd()
    }
  end
end

local function restoreSelection(container)
  if not container.selectionRanges then
    return
  end

  for index, range in pairs(container.selectionRanges) do
    local message = container:getChildByIndex(index)
    if message then
      message:setSelection(range.start, range.finish)
    end
  end
end

local function findMessageAt(container, anchor, anchorPoint, mousePos, mouseMoved)
  local children = container:getChildren()
  local count = #children
  if count == 0 then
    return nil, nil
  end

  -- UIManager supplies UI/screen coordinates and child rectangles use the
  -- same coordinates, including after a scroll-area virtual offset changes.
  local anchorPos = anchorPoint or (anchor and anchor:getLastClickPosition()) or mousePos
  local direction = mousePos.y - anchorPos.y
  if direction == 0 and mouseMoved then
    direction = mouseMoved.y
  end

  for index, message in ipairs(children) do
    if message:isExplicitlyVisible() then
      local top = message:getY()
      -- Rect coordinates are inclusive: a widget with height N occupies
      -- top..top + N - 1. Keeping the last pixel inside the message avoids
      -- treating the first pixel of the inter-message gap as message text.
      local bottom = top + message:getHeight() - 1
      if mousePos.y >= top and mousePos.y <= bottom then
        return message, nil
      end

      local nextMessage = children[index + 1]
      if nextMessage and mousePos.y > bottom and mousePos.y < nextMessage:getY() then
        -- A gap is a boundary, not a reason to select by viewport visibility.
        -- Dragging upward reaches the lower message first; dragging downward
        -- finishes at the upper message.
        if direction < 0 then
          return nextMessage, 0
        end
        return message, getTextLength(message)
      end
    end
  end

  if mousePos.y < children[1]:getY() then
    return children[1], 0
  end
  return children[count], getTextLength(children[count])
end

local function updateSelection(container, anchor, anchorTextPos, anchorPoint, mousePos, mouseMoved)
  local target, gapPosition = findMessageAt(container, anchor, anchorPoint, mousePos, mouseMoved)
  if not target then
    return false
  end

  local selfIndex = getMessageIndex(container, anchor)
  local targetIndex = getMessageIndex(container, target)
  if selfIndex <= 0 or targetIndex <= 0 then
    return false
  end

  local textBegin = anchorTextPos or anchor:getTextPos(anchorPoint)
  local textPos = gapPosition or target:getTextPos(mousePos)
  if textBegin < 0 or textPos < 0 then
    return false
  end

  local selectionAnchor = container._messageSelectionAnchor
  local selectionAnchorPoint = container._messageSelectionAnchorPoint
  local selectionAnchorTextPos = container._messageSelectionAnchorTextPos
  UITextMessageSelection.clear(container)
  container.selectionRanges = { }
  container._messageSelectionAnchor = selectionAnchor
  container._messageSelectionAnchorPoint = selectionAnchorPoint
  container._messageSelectionAnchorTextPos = selectionAnchorTextPos

  container.selection = {
    first = math.min(selfIndex, targetIndex),
    last = math.max(selfIndex, targetIndex)
  }

  if target == anchor then
    setMessageSelection(container, anchor, textBegin, textPos)
  else
    if targetIndex > selfIndex then
      setMessageSelection(container, anchor, textBegin, getTextLength(anchor))
    else
      setMessageSelection(container, anchor, 0, textBegin)
    end

    for index = container.selection.first + 1, container.selection.last - 1 do
      local selectedMessage = container:getChildByIndex(index)
      if selectedMessage then
        selectedMessage:selectAll()
        container.selectionRanges[index] = {
          start = selectedMessage:getSelectionStart(),
          finish = selectedMessage:getSelectionEnd()
        }
      end
    end

    if targetIndex > selfIndex then
      setMessageSelection(container, target, 0, textPos)
    else
      setMessageSelection(container, target, getTextLength(target), textPos)
    end
  end

  updateSelectionText(container)
  return true
end

updateSelectionText = function(container)
  if not container.selection then
    container.selectionText = nil
    return
  end

  local text = { }
  for index = container.selection.first, container.selection.last do
    local message = container:getChildByIndex(index)
    if message then
      local range = container.selectionRanges and container.selectionRanges[index]
      if range then
        table.insert(text, message:getText():sub(range.start + 1, range.finish))
      else
        table.insert(text, message:getSelection())
      end
    end
  end
  container.selectionText = table.concat(text, '\n')
end

function UITextMessageSelection.clear(container)
  for _, message in pairs(container:getChildren()) do
    message:clearSelection()
  end
  container.selectionText = nil
  container.selection = nil
  container.selectionRanges = nil
  container._messageSelectionAnchor = nil
  container._messageSelectionAnchorPoint = nil
  container._messageSelectionAnchorTextPos = nil
end

function UITextMessageSelection.selectAll(container)
  UITextMessageSelection.clear(container)
  if container:getChildCount() == 0 then
    return
  end

  local text = { }
  container.selectionRanges = { }
  for _, message in ipairs(container:getChildren()) do
    message:selectAll()
    local index = container:getChildIndex(message)
    container.selectionRanges[index] = {
      start = message:getSelectionStart(),
      finish = message:getSelectionEnd()
    }
    table.insert(text, message:getText():sub(message:getSelectionStart() + 1, message:getSelectionEnd()))
  end

  container.selectionText = table.concat(text, '\n')
  container.selection = {
    first = container:getChildIndex(container:getFirstChild()),
    last = container:getChildIndex(container:getLastChild())
  }
end

function UITextMessageSelection.copy(container)
  restoreSelection(container)
  updateSelectionText(container)

  local text = container.selectionText
  if not text then
    return ''
  end

  g_window.setClipboardText(text)
  return text
end

function UITextMessageSelection.attach(container, message)
  if not container._messageSelectionAttached then
    container._messageSelectionAttached = true
    container:setDraggable(true)

    local previousOnScrollChange = container.onScrollChange
    container.onScrollChange = function(self, virtualOffset)
      if previousOnScrollChange then
        previousOnScrollChange(self, virtualOffset)
      end

      if not self.selectionRanges then
        return
      end

      local anchor = self._messageSelectionAnchor
      local mousePos = g_window.getMousePosition()
      if anchor and g_window.isMouseButtonPressed(MouseLeftButton) and self:containsPoint(mousePos) then
        updateSelection(self, anchor, self._messageSelectionAnchorTextPos,
          self._messageSelectionAnchorPoint, mousePos, { x = 0, y = 0 })
      else
        -- Scrolling changes each message's screen geometry. Reapply the
        -- stable source ranges so selection painting follows the messages.
        restoreSelection(self)
        updateSelectionText(self)
      end
    end

    container.onMousePress = function(self, mousePos, button)
      if button ~= MouseLeftButton then
        return false
      end

      local target, gapPosition = findMessageAt(self, nil, mousePos, mousePos, { y = 0 })
      if not target then
        return false
      end

      UITextMessageSelection.clear(self)
      self._messageSelectionAnchor = target
      self._messageSelectionAnchorPoint = mousePos
      self._messageSelectionAnchorTextPos = gapPosition or target:getTextPos(mousePos)
      return true
    end

    container.onDragEnter = function(self, mousePos)
      return self._messageSelectionAnchor ~= nil
    end

    container.onDragMove = function(self, mousePos, mouseMoved)
      if not self._messageSelectionAnchor then
        return false
      end
      return updateSelection(self, self._messageSelectionAnchor,
        self._messageSelectionAnchorTextPos, self._messageSelectionAnchorPoint,
        mousePos, mouseMoved)
    end

    container.onDragLeave = function(self, droppedWidget, mousePos)
      updateSelectionText(self)
      self._messageSelectionAnchor = nil
      self._messageSelectionAnchorPoint = nil
      self._messageSelectionAnchorTextPos = nil
      return true
    end
  end

  message.onMousePress = function(self, mousePos, button)
    if button == MouseLeftButton then
      UITextMessageSelection.clear(container)
    end
  end

  message.onDragEnter = function(self, mousePos)
    UITextMessageSelection.clear(container)
    container._messageSelectionAnchor = self
    container._messageSelectionAnchorPoint = self:getLastClickPosition()
    container._messageSelectionAnchorTextPos = self:getTextPos(container._messageSelectionAnchorPoint)
    return true
  end

  message.onDragLeave = function(self, droppedWidget, mousePos)
    updateSelectionText(container)
    container._messageSelectionAnchor = nil
    container._messageSelectionAnchorPoint = nil
    container._messageSelectionAnchorTextPos = nil
    return true
  end

  message.onDragMove = function(self, mousePos, mouseMoved)
    local anchor = container._messageSelectionAnchor or self
    local anchorPoint = container._messageSelectionAnchorPoint or self:getLastClickPosition()
    local anchorTextPos = container._messageSelectionAnchorTextPos
    if anchorTextPos == nil then
      anchorTextPos = anchor:getTextPos(anchorPoint)
    end
    return updateSelection(container, anchor, anchorTextPos, anchorPoint, mousePos, mouseMoved)
  end
end
