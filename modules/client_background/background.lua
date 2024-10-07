g_locales.loadLocales(resolvepath(''))

_G.ClientBackground = { }



local background
-- local particles
local clientVersionLabel

local musicFilename = '/audios/music/quest/nox/shell'
local musicChannel

if g_sounds then
  musicChannel = g_sounds.getChannel(AudioChannels.Music)
  g_sounds.preload(musicFilename)
end

function ClientBackground.init()
  -- Alias
  ClientBackground.m = modules.client_background

  background = g_ui.displayUI('background')
  background:lower()

  -- particles = background:getChildById('particles')

  clientVersionLabel = background:getChildById('clientVersionLabel')
  clientVersionLabel:setText(f('%s\n%s', g_app.getName(), f(loc'${BackgroundClientVersion}', CLIENT_VERSION)))
  -- clientVersionLabel:setText(g_app.getName() .. ' ' .. g_app.getVersion() .. '\n' ..
  --                            'Rev  ' .. g_app.getBuildRevision() .. ' (' .. g_app.getBuildCommit() .. ')\n' ..
  --                            'Built on ' .. g_app.getBuildDate() .. ' for arch ' .. g_app.getBuildArch() .. '\n' ..
  --                            g_app.getBuildCompiler())

  if musicChannel then
    musicChannel:play(musicFilename, 1.0, -1, 7) -- Startup music
  end

  if not g_game.isOnline() then
    addEvent(function()
      ClientBackground.show()
    end)
  end

  connect(g_game, {
    onGameStart = ClientBackground.onGameStart,
    onGameEnd = ClientBackground.onGameEnd,
  })
end

function ClientBackground.terminate()
  disconnect(g_game, {
    onGameEnd = ClientBackground.onGameEnd,
    onGameStart = ClientBackground.onGameStart,
  })

  g_effects.cancelFade(clientVersionLabel)
  -- g_effects.cancelFade(particles)

  background:destroy()

  background = nil
  -- particles = nil
  clientVersionLabel = nil

  _G.ClientBackground = nil
end

function ClientBackground.onGameStart()
  ClientBackground.hide()
  ClientAudio.clearAudios()
end

function ClientBackground.onGameEnd()
  ClientAudio.clearAudios()
  if musicChannel then
    musicChannel:play(musicFilename, 1.0, -1, 7) -- Startup music
  end
  ClientBackground.show()
end



function ClientBackground.show()
  background:show()
  -- ClientBackground.showParticles()
  ClientBackground.showVersionLabel()
end

function ClientBackground.hide()
  ClientBackground.hideVersionLabel()
  -- ClientBackground.hideParticles()
  background:hide()
end

-- Particles

--[=[
function ClientBackground.showParticles()
  particles:show()
  g_effects.fadeIn(particles, 3000)
end

function ClientBackground.hideParticles()
  g_effects.cancelFade(particles)
  particles:hide()
end
]=]

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
