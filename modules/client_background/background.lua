g_locales.loadLocales(resolvepath(''))

_G.ClientBackground = { }



local background
local particles
local logo
local clientVersionLabel
local logoBaseSize
local logoScaleRetryEvent

local musicDirectory = '/audios/_enter_game'
local defaultMusic = musicDirectory .. '/shell.ogg'
local musicFilename = defaultMusic
local musicChannel
local backgroundPath = '/images/ui/enter_game/background'
local defaultBackground = backgroundPath .. '/background.png'

if g_sounds then
  musicChannel = g_sounds.getChannel(AudioChannels.Music)
  g_sounds.preload()
end

local function playBackgroundMusic()
  if not musicChannel then
    return
  end

  musicChannel:stopAudioGroup(musicFilename)
  musicChannel:clearAudioGroup(musicFilename)
  musicChannel:play(musicFilename, 1.0, -1, 7, 1.0) -- Startup music
end

local function getRandomMusic()
  local musicFiles = { }

  for _, file in ipairs(g_resources.listDirectoryFiles(musicDirectory)) do
    if file:match('^.+%.ogg$') then
      local path = musicDirectory .. '/' .. file
      if g_resources.fileExists(path) then
        table.insert(musicFiles, path)
      end
    end
  end

  if #musicFiles == 0 then
    return defaultMusic
  end

  return musicFiles[math.random(#musicFiles)]
end

local function getRandomBackground()
  local backgrounds = { }

  for _, file in ipairs(g_resources.listDirectoryFiles(backgroundPath)) do
    if file:match('%.png$') then
      local path = backgroundPath .. '/' .. file
      if g_resources.fileExists(path) then
        table.insert(backgrounds, path)
      end
    end
  end

  if #backgrounds == 0 then
    return defaultBackground
  end

  return backgrounds[math.random(#backgrounds)]
end

function ClientBackground.init()
  -- Alias
  ClientBackground.m = modules.client_background

  background = g_ui.displayUI('background')
  background:setImageSource(getRandomBackground())
  background:lower()

  musicFilename = getRandomMusic()

  particles = background:getChildById('particles')

  logo = background.logo
  logoBaseSize = nil

  clientVersionLabel = background:getChildById('clientVersionLabel')
  clientVersionLabel:setText(f('%s\n%s', g_app.getName(), f(loc'${BackgroundClientVersion}', CLIENT_VERSION_NAME)))
  -- clientVersionLabel:setText(g_app.getName() .. ' ' .. g_app.getVersion() .. '\n' ..
  --                            'Rev  ' .. g_app.getBuildRevision() .. ' (' .. g_app.getBuildCommit() .. ')\n' ..
  --                            'Built on ' .. g_app.getBuildDate() .. ' for arch ' .. g_app.getBuildArch() .. '\n' ..
  --                            g_app.getBuildCompiler())

  playBackgroundMusic()

  if g_game.isOnline() then
    ClientBackground.hide()
  else
    addEvent(function()
      ClientBackground.show()
    end)
  end

  connect(g_game, {
    onGameStart = ClientBackground.onGameStart,
    onGameEnd = ClientBackground.onGameEnd,
  })

  connect(background, {
    onGeometryChange = ClientBackground.onGeometryChange,
  })

  addEvent(ClientBackground.updateLogoScaleByWindowFactor)
end

function ClientBackground.terminate()
  disconnect(g_game, {
    onGameEnd = ClientBackground.onGameEnd,
    onGameStart = ClientBackground.onGameStart,
  })
  disconnect(background, {
    onGeometryChange = ClientBackground.onGeometryChange,
  })

  g_effects.cancelFade(logo)
  g_effects.cancelFade(clientVersionLabel)
  g_effects.cancelFade(particles)
  removeEvent(logoScaleRetryEvent)
  logoScaleRetryEvent = nil

  background:destroy()

  background = nil
  particles = nil
  logo = nil
  clientVersionLabel = nil
  logoBaseSize = nil

  _G.ClientBackground = nil
end

function ClientBackground.onGameStart()
  ClientBackground.hide()
  ClientAudio.clearAudios()
end

function ClientBackground.onGameEnd()
  ClientAudio.clearAudios()
  playBackgroundMusic()
  ClientBackground.show()
end

function ClientBackground.onGeometryChange()
  ClientBackground.updateLogoScaleByWindowFactor()
end

local function rememberLogoBaseSize()
  if logoBaseSize then
    return true
  end

  if not logo then
    return false
  end

  local currentSize = logo:getSize()
  if currentSize.width <= 0 or currentSize.height <= 0 then
    return false
  end

  logoBaseSize = {
    width = currentSize.width,
    height = currentSize.height
  }
  return true
end

function ClientBackground.updateLogoScaleByWindowFactor()
  if not logo then
    return
  end

  if not rememberLogoBaseSize() then
    removeEvent(logoScaleRetryEvent)
    logoScaleRetryEvent = scheduleEvent(ClientBackground.updateLogoScaleByWindowFactor, 30)
    return
  end

  local windowHeight = g_window.getSize().height
  local displayHeight = g_window.getDisplaySize().height
  if windowHeight <= 0 or displayHeight <= 0 then
    return
  end

  local factor = windowHeight / displayHeight
  local scaledWidth = math.max(1, math.floor(logoBaseSize.width * factor + 0.5))
  local scaledHeight = math.max(1, math.floor(logoBaseSize.height * factor + 0.5))
  logo:setSize({
    width = scaledWidth,
    height = scaledHeight
  })
end



function ClientBackground.show()
  background:show()
  ClientBackground.showParticles()
  ClientBackground.showLogo()
  ClientBackground.showVersionLabel()
end

function ClientBackground.hide()
  ClientBackground.hideVersionLabel()
  ClientBackground.hideLogo()
  ClientBackground.hideParticles()
  background:hide()
end

-- Particles

function ClientBackground.showParticles()
  particles:show()
  g_effects.fadeIn(particles, 3000)
end

function ClientBackground.hideParticles()
  g_effects.cancelFade(particles)
  particles:hide()
end

-- Logo

function ClientBackground.showLogo()
  logo:show()
  g_effects.fadeIn(logo, 3000)
end

function ClientBackground.hideLogo()
  g_effects.cancelFade(logo)
  logo:hide()
end

-- Version label

function ClientBackground.showVersionLabel()
  clientVersionLabel:show()
  g_effects.fadeIn(clientVersionLabel, 3000)
end

function ClientBackground.hideVersionLabel()
  g_effects.cancelFade(clientVersionLabel)
  clientVersionLabel:hide()
end

function ClientBackground.setVersionLabelText(text)
  clientVersionLabel:setText(text)
end



function ClientBackground.getBackground()
  return background
end
