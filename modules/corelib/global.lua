-- @docvars @{

-- root widget
rootWidget = g_ui.getRootWidget()
modules = package.loaded

-- G is used as a global table to save variables in memory between reloads
G = G or { }

-- @}

-- @docfuncs @{

local function createCallbackWithArgs(callback, args, argsCount)
  return function()
    return callback(unpack(args, 1, argsCount))
  end
end

function addEvent(callback, delayOrFront, ...)
  local ok, info = pcall(debug.getinfo, callback, 'S')
  local name = ok and info and ((info.short_src or 'lua') .. ':' .. (info.linedefined or 0)) or 'lua'
  local callbackWithArgs = createCallbackWithArgs(callback, {...}, select('#', ...))
  local event
  if delayOrFront == nil or type(delayOrFront) == 'boolean' then
    local front = delayOrFront == true
    event = g_dispatcher.addImmediateEventEx and g_dispatcher.addImmediateEventEx(name, callbackWithArgs, front) or g_dispatcher.addImmediateEvent(callbackWithArgs, front)
  else
    event = g_dispatcher.addEventEx and g_dispatcher.addEventEx(name, callbackWithArgs, delayOrFront) or g_dispatcher.addEvent(callbackWithArgs, delayOrFront)
  end
  -- must hold a reference to the callback, otherwise it would be collected
  event._callback = callbackWithArgs
  return event
end

function cycleEvent(callback, interval, ...)
  local ok, info = pcall(debug.getinfo, callback, 'S')
  local name = ok and info and ((info.short_src or 'lua') .. ':' .. (info.linedefined or 0)) or 'lua'
  local callbackWithArgs = createCallbackWithArgs(callback, {...}, select('#', ...))
  local event = g_dispatcher.cycleEventEx and g_dispatcher.cycleEventEx(name, callbackWithArgs, interval) or g_dispatcher.cycleEvent(callbackWithArgs, interval)
  -- must hold a reference to the callback, otherwise it would be collected
  event._callback = callbackWithArgs
  return event
end

function periodicalEvent(eventFunc, conditionFunc, delay, autoRepeatDelay)
  delay = delay or 30
  autoRepeatDelay = autoRepeatDelay or delay

  local func
  func = function()
    if conditionFunc and not conditionFunc() then
      func = nil
      return
    end
    eventFunc()
    addEvent(func, delay)
  end

  addEvent(function()
    func()
  end, autoRepeatDelay)
end

function removeEvent(event)
  if event then
    event:cancel()
    event._callback = nil
  end
end

local function createWeakRef(value)
  return setmetatable({ value = value }, { __mode = 'v' })
end

-- Keep only a weak handle to the widget to avoid retaining destroyed widget references through timer callback closures
function withWeakWidget(widget, callback)
  local weakWidget = createWeakRef(widget)
  return function(...)
    local currentWidget = weakWidget.value
    if isWidgetAlive(currentWidget) then
      return callback(currentWidget, ...)
    end
  end
end

function isWidget(widget)
  return type(widget) == 'userdata' and type(widget.getStyleName) == 'function'
end

function isWidgetAlive(widget)
  return widget and not widget:isDestroyed()
end

dofile 'compat'

if not json then
  json = require 'json'
end

-- @}
