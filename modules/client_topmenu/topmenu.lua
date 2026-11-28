g_locales.loadLocales(resolvepath(''))

_G.ClientTopMenu = { }



local topMenu
local leftButtonsPanel
local rightButtonsPanel
local leftGameButtonsPanel
local rightGameButtonsPanel



local function addButton(id, description, icon, callback, panel, toggle, front)
  local class
  if toggle then
    class = 'TopToggleButton'
  else
    class = 'TopButton'
  end

  local button = panel:getChildById(id)

  if not button then
    button = g_ui.createWidget(class)
    if front then
      panel:insertChild(1, button)
    else
      panel:addChild(button)
    end
  end

  button:setId(id)
  if type(description) == 'table' then --workaround
    button.loct = description.loct
    button.locpar = description.locpar
    button:updateLocale(button.locpar)
  else
    button:setTooltip(description)
  end
  button:setIcon(resolvepath(icon, 3))

  function button:onMouseRelease(pos, button)
    if self:containsPoint(pos) and button ~= MouseMidButton then
      callback()
      g_sounds.getChannel(AudioChannels.Gui):play(f('%s/button_2.ogg', getAudioChannelPath(AudioChannels.Gui)), 1.)
      return true
    end
  end

  return button
end



function ClientTopMenu.init()
  -- Alias
  ClientTopMenu.m = modules.client_topmenu

  connect(g_game, {
    onGameStart = ClientTopMenu.online,
    onGameEnd   = ClientTopMenu.offline
  })

  topMenu = g_ui.displayUI('topmenu')

  leftButtonsPanel = topMenu:getChildById('leftButtonsPanel')
  rightButtonsPanel = topMenu:getChildById('rightButtonsPanel')
  leftGameButtonsPanel = topMenu:getChildById('leftGameButtonsPanel')
  rightGameButtonsPanel = topMenu:getChildById('rightGameButtonsPanel')

  if g_game.isOnline() then
    ClientTopMenu.online()
  else
    ClientTopMenu.offline()
  end
end

function ClientTopMenu.terminate()
  disconnect(g_game, {
    onGameStart = ClientTopMenu.online,
    onGameEnd   = ClientTopMenu.offline
  })

  topMenu:destroy()
  topMenu = nil
  leftButtonsPanel = nil
  rightButtonsPanel = nil
  leftGameButtonsPanel = nil
  rightGameButtonsPanel = nil

  _G.ClientTopMenu = nil
end



function ClientTopMenu.online()
  topMenu:hide()
  ClientTopMenu.showGameButtons()
end

function ClientTopMenu.offline()
  ClientTopMenu.hideGameButtons()
  topMenu:show()
end

function ClientTopMenu.addLeftButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftButtonsPanel, false, front)
end

function ClientTopMenu.addLeftToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftButtonsPanel, true, front)
end

function ClientTopMenu.addRightButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightButtonsPanel, false, front)
end

function ClientTopMenu.addRightToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightButtonsPanel, true, front)
end

function ClientTopMenu.addLeftGameButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftGameButtonsPanel, false, front)
end

function ClientTopMenu.addLeftGameToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftGameButtonsPanel, true, front)
end

function ClientTopMenu.addRightGameButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightGameButtonsPanel, false, front)
end

function ClientTopMenu.addRightGameToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightGameButtonsPanel, true, front)
end

function ClientTopMenu.showGameButtons()
  leftGameButtonsPanel:show()
  rightGameButtonsPanel:show()
end

function ClientTopMenu.hideGameButtons()
  leftGameButtonsPanel:hide()
  rightGameButtonsPanel:hide()
end

function ClientTopMenu.getButton(id)
  return topMenu:recursiveGetChildById(id)
end

function ClientTopMenu.getTopMenu()
  return topMenu
end
