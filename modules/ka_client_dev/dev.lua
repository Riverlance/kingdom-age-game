g_locales.loadLocales(resolvepath(''))

_G.ClientDev = { }



local developmentWindow
local localCheckBox
local devCheckBox
local drawBoxesCheckBox
local hideMapCheckBox
local showDebugInfoCheckBox

local debugInfoHorizontalSeparator
local debugInfoLabel
local debugInfoPanel

local positionLabel
local relativePositionLabel
local sizeLabel
local widgetIdLabel
local widgetClassNameLabel
local widgetStyleNameLabel
local parentWidgetIdLabel
local parentWidgetClassNameLabel
local parentWidgetStyleNameLabel

local tempIp              = ClientEnterGame.clientIp
local tempPort            = ClientEnterGame.clientPort
local tempProtocolVersion = ClientEnterGame.clientProtocolVersion

local hasLoggedOnce = false



local function onLocalCheckBoxChange(self, value, oldValue)
  tempIp = value and ClientEnterGame.localIp or ClientEnterGame.clientIp

  ClientEnterGame.setUniqueServer(tempIp, tempPort, tempProtocolVersion)
end

local function onDevCheckBoxChange(self, value, oldValue)
  tempPort = value and '7175' or '7171'

  ClientEnterGame.setUniqueServer(tempIp, tempPort, tempProtocolVersion)
end

local function onDrawBoxesCheckBoxChange(self, value, oldValue)
  draw_debug_boxes(value)
end

local function onHideMapCheckBoxChange(self, value, oldValue)
  if value then
    hide_map()
  else
    show_map()
  end
end

local function showDebugInfo()
  developmentWindow:setHeight(550)
  debugInfoHorizontalSeparator:show()
  debugInfoLabel:show()
  debugInfoPanel:show()
end

local function hideDebugInfo()
  debugInfoPanel:hide()
  debugInfoLabel:hide()
  debugInfoHorizontalSeparator:hide()
  developmentWindow:setHeight(125)
end

local function onShowDebugInfoCheckBox(self, value)
  if value then
    showDebugInfo()
  else
    hideDebugInfo()
  end
end

local function onGameStart()
  hasLoggedOnce = true
end

local function updateDebugInfoWidgetText(widget, idLabel, classNameLabel, styleNameLabel, isParent)
  local id    = widget and widget:getId()
  local class = widget and widget:getClassName()
  local style = widget and widget:getStyleName()

  idLabel:setText(f('%s - %s', isParent and loc'${KaClientDevWidgetParentId}' or loc'${KaClientDevWidgetId}', string.exists(id) and id or loc'${CorelibInfoNone}'))
  classNameLabel:setText(f('%s - %s', isParent and loc'${KaClientDevWidgetParentClass}' or loc'${CorelibInfoClass}', string.exists(class) and class or loc'${CorelibInfoNone}'))
  styleNameLabel:setText(f('%s - %s', isParent and loc'${KaClientDevWidgetParentStyle}' or loc'${KaClientDevWidgetStyle}', string.exists(style) and style or loc'${CorelibInfoNone}'))
end

-- Main widget
local function updateMainWidgetDebugInfoText(mousePos)
  widget             = g_game.getWidgetByPos(mousePos) -- Overwrites default rootWidget
  local parentWidget = widget and widget:getParent()

  -- Widget
  updateDebugInfoWidgetText(widget, widgetIdLabel, widgetClassNameLabel, widgetStyleNameLabel)

  -- Parent widget
  updateDebugInfoWidgetText(parentWidget, parentWidgetIdLabel, parentWidgetClassNameLabel, parentWidgetStyleNameLabel, true)
end

-- Phantom widget
local function updatePhantomWidgetDebugInfoText(mousePos)
  local phantomWidget       = g_game.getWidgetByPos(mousePos, true)
  local phantomParentWidget = phantomWidget and phantomWidget:getParent()

  -- Widget
  updateDebugInfoWidgetText(phantomWidget, phantomWidgetIdLabel, phantomWidgetClassNameLabel, phantomWidgetStyleNameLabel)

  -- Parent widget
  updateDebugInfoWidgetText(phantomParentWidget, phantomParentWidgetIdLabel, phantomParentWidgetClassNameLabel, phantomParentWidgetStyleNameLabel, true)
end

-- Focused widget
local function updateFocusedWidgetDebugInfoText()
  local focusedWidget = rootWidget:getFocusedChild() or rootWidget
  while (focusedWidget:getFocusedChild()) do
    focusedWidget = focusedWidget:getFocusedChild()
  end
  local focusedParentWidget = focusedWidget and focusedWidget:getParent()

  -- Widget
  updateDebugInfoWidgetText(focusedWidget, focusedWidgetIdLabel, focusedWidgetClassNameLabel, focusedWidgetStyleNameLabel)

  -- Parent widget
  updateDebugInfoWidgetText(focusedParentWidget, focusedParentWidgetIdLabel, focusedParentWidgetClassNameLabel, focusedParentWidgetStyleNameLabel, true)
end

local function updateDebugInfo(mousePos, mouseMoved) -- ([mousePos [, mouseMoved]])
  if not developmentWindow or developmentWindow:isHidden() or not showDebugInfoCheckBox:isChecked() then
    return
  end

  if not mouseMoved then
    mouseMoved = { x = 0, y = 0 }
  end

  if not mousePos then
    mousePos = g_window.getMousePosition()
  end

  widget = g_game.getWidgetByPos(mousePos) -- Overwrites default rootWidget

  -- Position, Relative position, Size
  local relativeX = widget and math.max(0, mousePos.x - widget:getX()) or 0
  local relativeY = widget and math.max(0, mousePos.y - widget:getY()) or 0
  local width     = widget and widget:getWidth() or 0
  local height    = widget and widget:getHeight() or 0
  positionLabel:setText(f(loc'${KaClientDevWidgetPos}: (%d, %d)', mousePos.x, mousePos.y))
  relativePositionLabel:setText(f(loc'${KaClientDevWidgetRelativePos}: (%d, %d)', relativeX, relativeY))
  sizeLabel:setText(f(loc'${KaClientDevWidgetSize}: (%d, %d)', width, height))

  -- Main widget
  updateMainWidgetDebugInfoText(mousePos)

  -- Phantom widget
  updatePhantomWidgetDebugInfoText(mousePos)

  -- Focused widget
  updateFocusedWidgetDebugInfoText()
end

-- Note: 'widget' parameter is ignored
local function onMouseMove(widget, mousePos, mouseMoved) -- (widget, mousePos, mouseMoved) or ()
  updateDebugInfo(mousePos, mouseMoved)
end

local function onWidgetFocusChange(rootWidget, focused, widget, reason)
  updateDebugInfo()
end



function ClientDev.init()
  -- Alias
  ClientDev.m = modules.ka_client_dev

  ClientDev.reconnectToDefaultServer()

  developmentWindow     = g_ui.displayUI('dev')
  localCheckBox         = developmentWindow:getChildById('localCheckBox')
  devCheckBox           = developmentWindow:getChildById('devCheckBox')
  drawBoxesCheckBox     = developmentWindow:getChildById('drawBoxesCheckBox')
  hideMapCheckBox       = developmentWindow:getChildById('hideMapCheckBox')
  showDebugInfoCheckBox = developmentWindow:getChildById('showDebugInfoCheckBox')

  debugInfoHorizontalSeparator = developmentWindow:getChildById('debugInfoHorizontalSeparator')
  debugInfoLabel               = developmentWindow:getChildById('debugInfoLabel')
  debugInfoPanel               = developmentWindow:getChildById('debugInfoPanel')

  positionLabel                     = debugInfoPanel:getChildById('positionLabel')
  relativePositionLabel             = debugInfoPanel:getChildById('relativePositionLabel')
  sizeLabel                         = debugInfoPanel:getChildById('sizeLabel')
  widgetIdLabel                     = debugInfoPanel:getChildById('widgetIdLabel')
  widgetClassNameLabel              = debugInfoPanel:getChildById('widgetClassNameLabel')
  widgetStyleNameLabel              = debugInfoPanel:getChildById('widgetStyleNameLabel')
  parentWidgetIdLabel               = debugInfoPanel:getChildById('parentWidgetIdLabel')
  parentWidgetClassNameLabel        = debugInfoPanel:getChildById('parentWidgetClassNameLabel')
  parentWidgetStyleNameLabel        = debugInfoPanel:getChildById('parentWidgetStyleNameLabel')
  phantomWidgetIdLabel              = debugInfoPanel:getChildById('phantomWidgetIdLabel')
  phantomWidgetClassNameLabel       = debugInfoPanel:getChildById('phantomWidgetClassNameLabel')
  phantomWidgetStyleNameLabel       = debugInfoPanel:getChildById('phantomWidgetStyleNameLabel')
  phantomParentWidgetIdLabel        = debugInfoPanel:getChildById('phantomParentWidgetIdLabel')
  phantomParentWidgetClassNameLabel = debugInfoPanel:getChildById('phantomParentWidgetClassNameLabel')
  phantomParentWidgetStyleNameLabel = debugInfoPanel:getChildById('phantomParentWidgetStyleNameLabel')
  focusedWidgetIdLabel              = debugInfoPanel:getChildById('focusedWidgetIdLabel')
  focusedWidgetClassNameLabel       = debugInfoPanel:getChildById('focusedWidgetClassNameLabel')
  focusedWidgetStyleNameLabel       = debugInfoPanel:getChildById('focusedWidgetStyleNameLabel')
  focusedParentWidgetIdLabel        = debugInfoPanel:getChildById('focusedParentWidgetIdLabel')
  focusedParentWidgetClassNameLabel = debugInfoPanel:getChildById('focusedParentWidgetClassNameLabel')
  focusedParentWidgetStyleNameLabel = debugInfoPanel:getChildById('focusedParentWidgetStyleNameLabel')

  -- Setup window
  developmentWindow:breakAnchors()
  developmentWindow:hide()
  developmentWindow:move(196, 43)

  hideDebugInfo()

  -- Bind key
  g_keyboard.bindKeyDown('Ctrl+Alt+D', ClientDev.toggleWindow)

  -- Connect
  connect(g_game, {
    onGameStart = onGameStart,
  })
  connect(localCheckBox, {
    onCheckChange = onLocalCheckBoxChange
  })
  connect(devCheckBox, {
    onCheckChange = onDevCheckBoxChange
  })
  connect(drawBoxesCheckBox, {
    onCheckChange = onDrawBoxesCheckBoxChange
  })
  connect(hideMapCheckBox, {
    onCheckChange = onHideMapCheckBoxChange
  })
  connect(showDebugInfoCheckBox, {
    onCheckChange = onShowDebugInfoCheckBox
  })
  connect(rootWidget, {
    onMouseMove         = onMouseMove,
    onWidgetFocusChange = onWidgetFocusChange,
  })
end

function ClientDev.terminate()
  -- Disconnect
  disconnect(rootWidget, {
    onMouseMove         = onMouseMove,
    onWidgetFocusChange = onWidgetFocusChange,
  })
  disconnect(showDebugInfoCheckBox, {
    onCheckChange = onShowDebugInfoCheckBox
  })
  disconnect(hideMapCheckBox, {
    onCheckChange = onHideMapCheckBoxChange
  })
  disconnect(drawBoxesCheckBox, {
    onCheckChange = onDrawBoxesCheckBoxChange
  })
  disconnect(devCheckBox, {
    onCheckChange = onDevCheckBoxChange
  })
  disconnect(localCheckBox, {
    onCheckChange = onLocalCheckBoxChange
  })
  disconnect(g_game, {
    onGameStart = onGameStart,
  })

  -- Unbind key
  g_keyboard.unbindKeyDown('Ctrl+Alt+D')

  -- Destroy window
  if developmentWindow then
    developmentWindow:destroy()
    developmentWindow = nil
  end
  localCheckBox                = nil
  devCheckBox                  = nil
  drawBoxesCheckBox            = nil
  hideMapCheckBox              = nil
  showDebugInfoCheckBox        = nil
  debugInfoHorizontalSeparator = nil
  debugInfoLabel               = nil
  debugInfoPanel               = nil
  positionLabel                = nil
  relativePositionLabel        = nil
  sizeLabel                    = nil
  widgetIdLabel                = nil
  widgetClassNameLabel         = nil
  widgetStyleNameLabel         = nil
  parentWidgetIdLabel          = nil
  parentWidgetClassNameLabel   = nil
  parentWidgetStyleNameLabel   = nil

  ClientDev.reconnectToDefaultServer()

  _G.ClientDev = nil
end



function ClientDev.reconnectToDefaultServer()
  tempIp              = ClientEnterGame.clientIp
  tempPort            = ClientEnterGame.clientPort
  tempProtocolVersion = ClientEnterGame.clientProtocolVersion

  ClientEnterGame.setUniqueServer(tempIp, tempPort, tempProtocolVersion)
end

function ClientDev.toggleWindow()
  if developmentWindow:isHidden() then
    developmentWindow:show()

    onMouseMove()

    -- Connect to local server by default
    if not hasLoggedOnce then
      localCheckBox:setChecked(true)
    end
  else
    developmentWindow:hide()
  end
end
