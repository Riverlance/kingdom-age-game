g_locales.loadLocales(resolvepath(''))

_G.GameUnjustifiedPoints = { }



local updateTime = 1 -- seconds
local GameUnjustifiedPointsActionKey = 'Ctrl+U'

unjustifiedPointsWindow = nil
unjustifiedPointsHeader = nil
unjustifiedPointsFooter = nil
unjustifiedPointsTopMenuButton = nil
contentsPanel = nil

currentSkullWidget = nil
skullTimeLabel = nil

redSkullProgressBar = nil
blackSkullProgressBar = nil

redSkullSkullWidget = nil
blackSkullSkullWidget = nil

updateMainLabelEvent = nil

local function updateMainLabelEventFunction()
  if not skullTimeLabel or not skullTimeLabel.data or skullTimeLabel.data.remainingTime <= 0 then
    return
  end

  local data = skullTimeLabel.data

  local remainingTime = data.remainingTime - updateTime
  if remainingTime >= 0 then
    GameUnjustifiedPoints.onUnjustifiedPoints(remainingTime, data.fragsToRedSkull, data.fragsToBlackSkull, data.timeToRemoveFrag)
  end
end

local function getColorByKills(kills, fragsTo)
  local ratio = kills / fragsTo
  if ratio == 0 then
    return 'white'
  end

  return ratio < 0.334 and 'green' or ratio < 0.667 and 'yellow' or ratio >= 0.667 and 'red' or 'white'
end



function GameUnjustifiedPoints.init()
  -- Alias
  GameUnjustifiedPoints.m = modules.game_unjustifiedpoints

  unjustifiedPointsWindow        = g_ui.loadUI('unjustifiedpoints')
  unjustifiedPointsHeader        = unjustifiedPointsWindow:getChildById('miniWindowHeader')
  unjustifiedPointsFooter        = unjustifiedPointsWindow:getChildById('miniWindowFooter')
  unjustifiedPointsTopMenuButton = ClientTopMenu.addRightGameToggleButton('unjustifiedPointsTopMenuButton', { loct = '${GameUnjustifiedPointsWindowTitle} (${GameUnjustifiedPointsActionKey})', locpar = { GameUnjustifiedPointsActionKey = GameUnjustifiedPointsActionKey } }, '/images/ui/top_menu/unjustifiedpoints', GameUnjustifiedPoints.toggle)

  unjustifiedPointsWindow.topMenuButton = unjustifiedPointsTopMenuButton
  unjustifiedPointsWindow:disableResize()
  unjustifiedPointsTopMenuButton:hide()

  contentsPanel = unjustifiedPointsWindow:getChildById('contentsPanel')

  skullTimeLabel = unjustifiedPointsHeader:getChildById('skullTimeLabel')
  currentSkullWidget = unjustifiedPointsFooter:getChildById('currentSkullWidget')

  redSkullProgressBar = contentsPanel:getChildById('redSkullProgressBar')
  blackSkullProgressBar = contentsPanel:getChildById('blackSkullProgressBar')
  redSkullSkullWidget = contentsPanel:getChildById('redSkullSkullWidget')
  blackSkullSkullWidget = contentsPanel:getChildById('blackSkullSkullWidget')

  GameUnjustifiedPoints.onUnjustifiedPoints()

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeUnjustifiedPoints, GameUnjustifiedPoints.parseUnjustifiedPoints)

  connect(g_game, {
    onGameStart = GameUnjustifiedPoints.online,
    onGameEnd   = GameUnjustifiedPoints.offline
  })

  g_keyboard.bindKeyDown(GameUnjustifiedPointsActionKey, GameUnjustifiedPoints.toggle)

  if g_game.isOnline() then
    GameUnjustifiedPoints.online()
  end
end

function GameUnjustifiedPoints.terminate()
  removeEvent(updateMainLabelEvent)
  updateMainLabelEvent = nil

  disconnect(g_game, {
    onGameStart = GameUnjustifiedPoints.online,
    onGameEnd   = GameUnjustifiedPoints.offline
  })

  g_keyboard.unbindKeyDown(GameUnjustifiedPointsActionKey)

  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeUnjustifiedPoints)

  unjustifiedPointsWindow:destroy()
  unjustifiedPointsTopMenuButton:destroy()

  _G.GameUnjustifiedPoints = nil
end

function GameUnjustifiedPoints.onMiniWindowOpen()
  if not g_game.isOnline() or not unjustifiedPointsWindow:isVisible() then
    return
  end

  updateMainLabelEvent = cycleEvent(updateMainLabelEventFunction, updateTime * 1000)
  g_game.sendUnjustifiedPointsBuffer()
end

function GameUnjustifiedPoints.onMiniWindowClose()
  removeEvent(updateMainLabelEvent)
  updateMainLabelEvent = nil
end

function GameUnjustifiedPoints.toggle()
  GameInterface.toggleMiniWindow(unjustifiedPointsWindow)
end

function GameUnjustifiedPoints.online()
  if g_game.getFeature(GameUnjustifiedPointsPacket) then
    unjustifiedPointsWindow:setup(unjustifiedPointsTopMenuButton)
    unjustifiedPointsTopMenuButton:show()
    g_game.sendUnjustifiedPointsBuffer()

    if unjustifiedPointsWindow:isVisible() then
      updateMainLabelEvent = cycleEvent(updateMainLabelEventFunction, updateTime * 1000)
    end
  else
    unjustifiedPointsTopMenuButton:hide()
    unjustifiedPointsWindow:close()
  end
end

function GameUnjustifiedPoints.offline()
  removeEvent(updateMainLabelEvent)
  updateMainLabelEvent = nil
end

function GameUnjustifiedPoints.onUnjustifiedPoints(remainingTime, fragsToRedSkull, fragsToBlackSkull, timeToRemoveFrag)
  if not g_game.isOnline() or not unjustifiedPointsWindow:isVisible() then
    return
  end

  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer:isLocalPlayer() then
    return
  end

  remainingTime     = remainingTime or 0
  fragsToRedSkull   = fragsToRedSkull or 0
  fragsToBlackSkull = fragsToBlackSkull or 0
  timeToRemoveFrag  = timeToRemoveFrag or 1
  local fragsCount  = math.ceil(remainingTime / timeToRemoveFrag)
  local skull       = localPlayer:getSkull()

  redSkullProgressBar:setPhases(fragsToRedSkull)
  blackSkullProgressBar:setPhases(fragsToBlackSkull)

  local nextFragRemainingTime = remainingTime % timeToRemoveFrag
  skullTimeLabel:setText(f(loc'%.2d:%.2d (${GameUnjustifiedPointsInfoFrags}: %d)', math.floor(nextFragRemainingTime / (60 * 60)), math.floor(nextFragRemainingTime / 60) % 60, fragsCount))

  local nextFragRemainingTimeTooltip = f(loc'${GameUnjustifiedPointsInfoNextFragTime}: %.2d:%.2d:%.2d', math.floor(nextFragRemainingTime / (60 * 60)), math.floor(nextFragRemainingTime / 60) % 60, nextFragRemainingTime % 60)
  skullTimeLabel:setTooltip(f(loc'${GameUnjustifiedPointsInfoTotalFrags}: %d\n%s\n${GameUnjustifiedPointsInfoFragsRemainingTime}: %.2d:%.2d:%.2d', fragsCount, nextFragRemainingTimeTooltip, math.floor(remainingTime / (60 * 60)), math.floor(remainingTime / 60) % 60, remainingTime % 60))

  skullTimeLabel.data = {
    remainingTime         = remainingTime,
    fragsToRedSkull       = fragsToRedSkull,
    fragsToBlackSkull     = fragsToBlackSkull,
    timeToRemoveFrag      = timeToRemoveFrag,
    nextFragRemainingTime = nextFragRemainingTime
  }

  if remainingTime >= 1 and table.contains({SkullWhite, SkullRed, SkullBlack}, skull) then
    currentSkullWidget:setIcon(getSkullImagePath(skull))
    currentSkullWidget:setTooltip(loc'${GameUnjustifiedPointsInfoCurrentSkull}')
  else
    currentSkullWidget:setIcon('')
    currentSkullWidget:setTooltip(loc'${GameUnjustifiedPointsInfoNoSkull}')
  end

  if fragsToRedSkull ~= 0 then
    redSkullProgressBar:setValue(fragsCount, 0, fragsToRedSkull)
    redSkullProgressBar:setFillerBackgroundColor(getColorByKills(fragsCount, fragsToRedSkull))
  else
    redSkullProgressBar:setValue(0, 0, 1)
  end
  redSkullProgressBar:setTooltip(loc'${GameUnjustifiedPointsInfoFragsUntilSkullRed}: ' .. math.max(0, fragsToRedSkull - fragsCount))

  if fragsToBlackSkull ~= 0 then
    blackSkullProgressBar:setValue(fragsCount, 0, fragsToBlackSkull)
    blackSkullProgressBar:setFillerBackgroundColor(getColorByKills(fragsCount, fragsToBlackSkull))
  else
    blackSkullProgressBar:setValue(0, 0, 1)
  end
  blackSkullProgressBar:setTooltip(loc'${GameUnjustifiedPointsInfoFragsUntilSkullBlack}: ' .. math.max(0, fragsToBlackSkull - fragsCount))
end

function GameUnjustifiedPoints.parseUnjustifiedPoints(protocolGame, opcode, msg)
  local buffer = msg:getString()
  local params = buffer / ':'

  local remainingTime     = tonumber(params[1])
  local fragsToRedSkull   = tonumber(params[2])
  local fragsToBlackSkull = tonumber(params[3])
  local timeToRemoveFrag  = tonumber(params[4])
  if not remainingTime or not fragsToRedSkull or not fragsToBlackSkull or not timeToRemoveFrag then
    return
  end

  GameUnjustifiedPoints.onUnjustifiedPoints(remainingTime, fragsToRedSkull, fragsToBlackSkull, timeToRemoveFrag)
end
