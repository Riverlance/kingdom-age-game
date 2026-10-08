-- Force a reload of the player settings file, if restarted
if g_playerSettings and g_playerSettings.terminate then
  g_playerSettings.terminate()
end



g_playerSettings = { }



local playerSettingsDirty = false
local playerSettingsSaveDelay = 250



local playerSettingsPath
local playerSettingsConfig
local playerSettingsSaveEvent



local function updatePlayerSettingsPath()
  if not g_game.isOnline() then
    return playerSettingsPath ~= nil
  end

  local serverHost = G.host
  local characterName = g_game.getCharacterName()
  if not serverHost or serverHost == '' or not characterName or characterName == '' then
    return false
  end

  serverHost = serverHost:gsub('^https?://', '')
  local newPath = f('/%s/%s', serverHost:gsub('[%W]', '_'):lower(), characterName:gsub('[%W]', '_'))
  if playerSettingsPath == newPath then
    return true
  end

  -- A new login can happen before the deferred logout flush runs. Save the
  -- previous character's Config before changing the active path.
  if playerSettingsDirty and not g_playerSettings.flushSave() then
    return false
  end

  playerSettingsPath = newPath
  playerSettingsConfig = nil
  return true
end

function g_playerSettings.get(fileName) -- ([fileName])
  if not updatePlayerSettingsPath() then
    return nil
  end

  if not g_resources.makeDir(playerSettingsPath) then
    g_logger.error(f('Failed to load path \'%s\'', playerSettingsPath))
  end

  local configName = fileName or 'config'
  local playerSettingsFilePath = f('%s/%s.otml', playerSettingsPath, configName)

  -- Create or load player settings file
  local file = g_configs.create(playerSettingsFilePath)
  if not file then
    g_logger.error(f('Failed to load file at \'%s\'', playerSettingsFilePath))
  elseif configName == 'config' then
    playerSettingsConfig = file
  end

  return file
end

function g_playerSettings.scheduleSave()
  playerSettingsConfig = g_playerSettings.get()
  if not playerSettingsConfig then
    return false
  end

  playerSettingsDirty = true

  g_playerSettings.cancelSave()
  playerSettingsSaveEvent = scheduleEvent(function()
    playerSettingsSaveEvent = nil
    g_playerSettings.flushSave()
  end, playerSettingsSaveDelay)
end

function g_playerSettings.cancelSave()
  removeEvent(playerSettingsSaveEvent)
  playerSettingsSaveEvent = nil
end

function g_playerSettings.flushSave()
  g_playerSettings.cancelSave()

  if not playerSettingsDirty then
    return false
  end

  -- Use the Config from the character that was modified. Calling get() here
  -- could switch to a new character after a fast logout/login cycle.
  local file = playerSettingsConfig
  if not file or not file:save() then
    return false
  end

  playerSettingsDirty = false
  return true
end



local function onGameStart()
  -- Flush any pending changes from the previous character before resolving the
  -- path for the new one.
  if playerSettingsDirty and not g_playerSettings.flushSave() then
    g_logger.error('Failed to flush player settings before changing character')
    return
  end

  g_playerSettings.get()
end

local function onGameEnd()
  -- Run after all other onGameEnd callbacks have updated player settings.
  scheduleEvent(g_playerSettings.flushSave)
end

local function onExit()
  g_playerSettings.flushSave()
end



function g_playerSettings.terminate()
  g_playerSettings.flushSave()

  disconnect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd,
  })

  disconnect(g_app, {
    onExit = onExit,
    onTerminate = g_playerSettings.terminate,
  })
end



-- Player settings are initialized before the client modules and flushed
-- after all game-end callbacks have had a chance to update their settings.
connect(g_game, {
  onGameStart = onGameStart,
  onGameEnd = onGameEnd,
})

connect(g_app, {
  onExit = onExit,
  onTerminate = g_playerSettings.terminate,
})
