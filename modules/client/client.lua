g_locales.loadLocales(resolvepath(''))

_G.Client = { }



local loadingBox
local isLoaded = false

function Client.init()
  -- Alias
  Client.m = modules.client

  connect(g_app, {
    onRun  = Client.startup,
    onExit = Client.exit
  })

  local platformType = g_window.getPlatformType()
  local isX11 = type(platformType) == 'string' and platformType:find('X11', 1, true) == 1
  local density = (isX11 and g_window.getDisplayDensity()) or 1
  local displaySize = g_window.getDisplaySize()
  local metricsSpace = g_settings.getString('window-metrics-space', '')
  local shouldScaleLegacySavedMetrics = isX11 and density ~= 1 and metricsSpace ~= 'physical-v1'

  local minSize = { width = 600, height = 480 }
  if isX11 then
    minSize.width = math.max(1, math.min(minSize.width, displaySize.width))
    minSize.height = math.max(1, math.min(minSize.height, displaySize.height))
  end
  g_window.setMinimumSize(minSize)

  -- initialize in fullscreen mode on mobile devices
  if g_window.getPlatformType() == 'X11-EGL' then
    g_window.setFullscreen(true)
  else
    -- window size
    local size = { width = 800, height = 600 }
    local hasSavedWindowSize = g_settings.exists('window-size')
    size = g_settings.getSize('window-size', size)
    if shouldScaleLegacySavedMetrics and hasSavedWindowSize then
      size = {
        width = math.floor((size.width * density) + 0.5),
        height = math.floor((size.height * density) + 0.5)
      }
    end

    if isX11 then
      size.width = math.max(1, math.min(size.width, displaySize.width))
      size.height = math.max(1, math.min(size.height, displaySize.height))
    end
    g_window.resize(size)

    -- window position, default is the screen center
    local defaultPos = { x = (displaySize.width - size.width) / 2, y = (displaySize.height - size.height) / 2 }
    local pos = defaultPos
    if not isX11 then
      pos = g_settings.getPoint('window-pos', defaultPos)
    end
    if isX11 then
      local maxX = math.max(displaySize.width - size.width, 0)
      local maxY = math.max(displaySize.height - size.height, 0)
      pos.x = math.max(0, math.min(pos.x, maxX))
      pos.y = math.max(0, math.min(pos.y, maxY))
    else
      pos.x = math.max(pos.x, 0)
      pos.y = math.max(pos.y, 0)
    end
    g_window.move(pos)

    -- window maximized?
    local maximized = g_settings.getBoolean('window-maximized', false)
    if maximized then
      g_window.maximize()
    end
  end

  g_window.setTitle(g_app.getName())
  g_window.setIcon('/images/client_icon')

  -- poll resize events
  g_window.poll()

  -- generate machine uuid, this is a security measure for storing passwords
  if not g_crypt.setMachineUUID(g_settings.get('uuid')) then
    g_settings.set('uuid', g_crypt.getMachineUUID())
    g_settings.save()
  end

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeOtclientSignal, Client.onRecvOtclientSignal)
end

function Client.terminate()
  disconnect(g_app, {
    onRun  = Client.startup,
    onExit = Client.exit
  })

  -- save window configs
  local platformType = g_window.getPlatformType()
  local isX11 = type(platformType) == 'string' and platformType:find('X11', 1, true) == 1
  g_settings.set('window-size', g_window.getUnmaximizedSize())
  if isX11 then
    g_settings.remove('window-pos')
    g_settings.set('window-metrics-space', 'physical-v1')
  else
    g_settings.set('window-pos', g_window.getUnmaximizedPos())
    g_settings.remove('window-metrics-space')
  end
  g_settings.set('window-maximized', g_window.isMaximized())

  _G.Client = nil
end



function Client.startup()
  connect(g_updater, {
    onUpdated = Client.loadFiles
  })
  connect(g_things, {
    onLoadDat = Client.onLoadFiles
  })
  connect(g_sprites, {
    onLoadSpr = Client.onLoadFiles
  })

  -- Check for startup errors
  if g_graphics.getRenderer():lower():match('gdi generic') then
    displayErrorBox(loc'${ClientGraphicsCardNotDetectedTitle}', loc'${ClientGraphicsCardNotDetectedMessage}')
  end
end

function Client.exit()
  disconnect(g_sprites, {
    onLoadSpr = Client.onLoadFiles
  })
  disconnect(g_things, {
    onLoadDat = Client.onLoadFiles
  })
  disconnect(g_updater, {
    onUpdated = Client.loadFiles
  })

  g_logger.info('Exiting application...\n\n\n')
end

function Client.onRecvOtclientSignal() -- From Server ProtocolGame::onRecvFirstMessage
  -- Nothing yet
end

function Client.onLoadFiles()
  if g_sprites.isLoaded() and g_things.isDatLoaded() then
    isLoaded = true
    ClientEnterGame.firstShow()
    if loadingBox then
      loadingBox:destroy()
      loadingBox = nil
    end
  end
end

local function tryLoadDatWithFallbacks(datPath)
  if g_things.loadDat(datPath) then
    return true
  end

  local featureFlags = {
    GameSpritesU32,
    GameEnhancedAnimations,
    GameIdleAnimations
  }

  local combinations = {
    { 1 }, { 2 }, { 3 },
    { 1, 2 }, { 1, 3 }, { 2, 3 },
    { 1, 2, 3 }
  }

  for _, combo in ipairs(combinations) do
    for _, index in ipairs(combo) do
      g_game.enableFeature(featureFlags[index])
    end

    if g_things.loadDat(datPath) then
      return true
    end
  end

  return false
end

function Client.loadFiles()
  disconnect(g_updater, {
    onUpdated = Client.loadFiles
  })

  loadingBox = displaySystemBox(loc'${CorelibInfoLoading}', loc'${ClientLoadingBoxMessage}')

  -- Client version
  g_game.setClientVersion(DefaultClientVersion)

  -- New limit of sprites
  g_game.enableFeature(GameSpritesU32) -- Automatically activated on 960+ protocol
  -- Alpha channel on sprites
  g_game.enableFeature(GameSpritesAlphaChannel)
  -- New limit of effects
  g_game.enableFeature(GameMagicEffectU16)
  g_game.enableFeature(GameDistanceEffectU16)

  scheduleEvent(function()
    local path = resolvepath('/things/Kingdom Age')
    local errorMessage = ''
    g_logger.setLevel(5)
    local datLoaded = tryLoadDatWithFallbacks(path)
    g_logger.setLevel(1)

    if not datLoaded then
      errorMessage = errorMessage .. f(loc'${ClientUnableToLoadDat}', path) .. '\n'
    end
    if not g_sprites.loadSpr(path) then
      errorMessage = errorMessage .. f(loc'${ClientUnableToLoadSpr}', path)
    end

    if #errorMessage > 0 then
      local messageBox = displayErrorBox(loc'${CorelibInfoError}', errorMessage)
      addEvent(function()
        if isWidgetAlive(messageBox) then
          messageBox:raise()
          messageBox:focus()
        end
      end)
      g_game.setClientVersion(0)
      g_game.setProtocolVersion(0)
    end
  end, 1)
end

function Client.isLoaded()
  return isLoaded
end
