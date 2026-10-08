g_locales.loadLocales(resolvepath(''))

_G.GameScreenshot = {}

local screenshotDirectory = g_resources.getWorkDir() .. 'output/screenshots'
local screenshotShortcut = 'Ctrl+Alt+S'
local screenshotEvent = nil
local onlyCaptureGameWindow = nil
local pendingMapCaptures = 0
local hiddenScreenshotWidgets = {}
local healthStateInitialized = false

local events = {
  screenshotEventLevelUp   = { setting = 'GameScreenshotLevelUp', default = true, label = 'LevelUp' },
  screenshotEventDeath     = { setting = 'GameScreenshotDeath', default = true, label = 'Death' },
  screenshotEventLowHealth = { setting = 'GameScreenshotLowHealth', default = false, label = 'LowHealth' }
}

local function eventEnabled(id)
  local event = events[id]
  return event and g_settings.getBoolean(event.setting, event.default)
end

local function safeName(name)
  return (name or 'player'):gsub('[^%w%-_]', '_')
end

local function hideScreenshotWidget(widget)
  if widget and not widget:isDestroyed() and widget:isVisible() then
    table.insert(hiddenScreenshotWidgets, widget)
    widget:setVisible(false)
  end
end

local function restoreScreenshotWidgets()
  for _, widget in ipairs(hiddenScreenshotWidgets) do
    if not widget:isDestroyed() then
      widget:setVisible(true)
    end
  end

  hiddenScreenshotWidgets = {}
  pendingMapCaptures = 0
end

local function takeScreenshot(fileName)
  if onlyCaptureGameWindow and onlyCaptureGameWindow:isChecked() then
    if pendingMapCaptures == 0 then
      if GameInterface and GameInterface.getBottomPanel then
        hideScreenshotWidget(GameInterface.getBottomPanel())
      end
      if GameInterface and GameInterface.getSplitter then
        hideScreenshotWidget(GameInterface.getSplitter())
      end

      if #hiddenScreenshotWidgets == 0 and GameConsole and GameConsole.getConsolePanel then
        hideScreenshotWidget(GameConsole.getConsolePanel())
      end
    end

    pendingMapCaptures = pendingMapCaptures + 1
    g_app.doMapScreenshot(fileName)
  else
    g_app.doScreenshot(fileName)
  end
end

local function capture(id)
  if not g_game.isOnline() or not g_settings.getBoolean('GameScreenshotEnabled', true) or not eventEnabled(id) then
    return
  end

  if screenshotEvent then
    removeEvent(screenshotEvent)
  end

  local player = g_game.getLocalPlayer()
  local playerName = player and player:getName() or 'player'
  local level = player and player:getLevel() or 0
  local event = events[id]
  local fileName = string.format('%s/%s_%d_%s_%s.png', screenshotDirectory, safeName(playerName), level,
    event.label, os.date('%Y%m%d%H%M%S'))

  screenshotEvent = scheduleEvent(function()
    screenshotEvent = nil
    takeScreenshot(fileName)
  end, 100)
end

function GameScreenshot.setEnabled(widget, checked)
  g_settings.set('GameScreenshotEnabled', checked)
end

function GameScreenshot.setEventEnabled(widget, checked)
  local event = events[widget:getId()]
  if event then
    g_settings.set(event.setting, checked)
  end
end

function GameScreenshot.setOnlyCaptureGameWindow(widget, checked)
  g_settings.set('onlyCaptureGameWindow', checked)
end

function GameScreenshot.onLevelChange(player, level, levelPercent, oldLevel)
  if oldLevel and oldLevel > 0 and level > oldLevel then
    capture('screenshotEventLevelUp')
  end
end

function GameScreenshot.onDeath()
  capture('screenshotEventDeath')
end

function GameScreenshot.onHealthChange(player, health, maxHealth, oldHealth, oldMaxHealth)
  if maxHealth <= 0 then
    return
  end

  if not healthStateInitialized then
    healthStateInitialized = true
    return
  end

  if oldHealth == nil or oldMaxHealth <= 0 then
    return
  end

  local threshold = 0.2
  if health / maxHealth <= threshold and oldHealth / oldMaxHealth > threshold then
    capture('screenshotEventLowHealth')
  end
end

function GameScreenshot.onGameStart()
  healthStateInitialized = false
end

function GameScreenshot.onGameEnd()
  healthStateInitialized = false

  if screenshotEvent then
    removeEvent(screenshotEvent)
    screenshotEvent = nil
  end
end

function GameScreenshot.takeManual()
  if not g_game.isOnline() then
    return
  end

  local player = g_game.getLocalPlayer()
  local playerName = player and player:getName() or 'player'
  local level = player and player:getLevel() or 0
  local fileName = string.format('%s/%s_%d_Manual_%s.png', screenshotDirectory, safeName(playerName), level,
    os.date('%Y%m%d%H%M%S'))
  takeScreenshot(fileName)
end

function GameScreenshot.onSaved(fileName)
  local message = f(loc'${GameScreenshotSaved}', g_resources.getFileName(fileName))
  if GameConsole and GameConsole.addServerLog then
    GameConsole.addServerLog(message)
  else
    g_logger.info(message)
  end
end

function GameScreenshot.onCaptureFinished()
  if pendingMapCaptures <= 0 then
    return
  end

  pendingMapCaptures = pendingMapCaptures - 1
  if pendingMapCaptures == 0 then
    restoreScreenshotWidgets()
    g_app.repaintForeground()
  end
end

function GameScreenshot.openFolder()
  g_platform.openDir(screenshotDirectory)
end

function GameScreenshot.init()
  local panel = ClientOptions.m.GraphicPanel

  local enabled = panel.screenshotEnabled
  enabled:setChecked(g_settings.getBoolean('GameScreenshotEnabled', true))
  connect(enabled, { onCheckChange = GameScreenshot.setEnabled })

  onlyCaptureGameWindow = panel.screenshotOnlyCaptureGameWindow
  onlyCaptureGameWindow:setChecked(g_settings.getBoolean('onlyCaptureGameWindow', false))
  connect(onlyCaptureGameWindow, { onCheckChange = GameScreenshot.setOnlyCaptureGameWindow })

  for id, event in pairs(events) do
    local widget = panel:getChildById(id)
    widget:setChecked(g_settings.getBoolean(event.setting, event.default))
    connect(widget, { onCheckChange = GameScreenshot.setEventEnabled })
  end

  connect(LocalPlayer, {
    onLevelChange = GameScreenshot.onLevelChange,
    onHealthChange = GameScreenshot.onHealthChange
  })
  connect(g_game, {
    onDeath = GameScreenshot.onDeath,
    onGameStart = GameScreenshot.onGameStart,
    onGameEnd = GameScreenshot.onGameEnd
  })
  g_keyboard.bindKeyDown(screenshotShortcut, GameScreenshot.takeManual)
end

function GameScreenshot.terminate()
  g_keyboard.unbindKeyDown(screenshotShortcut)
  if pendingMapCaptures > 0 then
    restoreScreenshotWidgets()
    g_app.repaintForeground()
  end
  if onlyCaptureGameWindow then
    g_settings.set('onlyCaptureGameWindow', onlyCaptureGameWindow:isChecked())
    disconnect(onlyCaptureGameWindow, { onCheckChange = GameScreenshot.setOnlyCaptureGameWindow })
  end
  disconnect(LocalPlayer, {
    onLevelChange = GameScreenshot.onLevelChange,
    onHealthChange = GameScreenshot.onHealthChange
  })
  disconnect(g_game, {
    onDeath = GameScreenshot.onDeath,
    onGameStart = GameScreenshot.onGameStart,
    onGameEnd = GameScreenshot.onGameEnd
  })

  GameScreenshot.onGameEnd()

  if screenshotEvent then
    removeEvent(screenshotEvent)
    screenshotEvent = nil
  end

  if screenshotPanel and not screenshotPanel:isDestroyed() then
    screenshotPanel:destroy()
  end

  screenshotPanel = nil
  onlyCaptureGameWindow = nil
end
