_G.GameTracker = { }

TrackingInfo = {
  Name     = 1,
  Position = 2,
  Outfit   = 3,
  Tracking = 251,
  Paused   = 252,
  Start    = 253,
  Stop     = 254,
  MsgEnd   = 255
}

trackedCreatures = { }
trackedPositions = { }
posIndex = 1

function GameTracker.init()
  GameTracker.m = modules.ka_game_tracker -- Alias
  ProtocolGame.registerOpcode(ServerOpcodes.ServerOpcodeTracking, GameTracker.onTrackCreature)
  connect(g_game, {
    onGameEnd = GameTracker.onGameEnd,
    onTrackPositionStart = GameTracker.startTrackPosition
  })
  connect(LocalPlayer, { onPositionChange = GameTracker.onLocalPlayerPositionChange })
end

function GameTracker.terminate()
  GameTracker.onGameEnd()
  disconnect(LocalPlayer, { onPositionChange = GameTracker.onLocalPlayerPositionChange })
  disconnect(g_game, {
    onGameEnd = GameTracker.onGameEnd,
    onTrackPositionStart = GameTracker.startTrackPosition
  })
  ProtocolGame.unregisterOpcode(ServerOpcodes.ServerOpcodeTracking, GameTracker.onTrackCreature)
  _G.GameTracker = nil
end

function GameTracker.onGameEnd()
  for id, trackedCreature in pairs(trackedCreatures) do
    trackedCreature.status = TrackingInfo.Stop
    signalcall(g_game.onTrackCreature, trackedCreature)
  end
  trackedCreatures = { }
  for index, posNode in pairs(trackedPositions) do
    GameTracker.stopTrackPosition(posNode.position)
  end
  trackedPositions = { }
  posIndex = 1
end

function GameTracker.onLocalPlayerPositionChange()
  for id, trackedCreature in pairs(trackedCreatures) do
    signalcall(g_game.onTrackCreature, trackedCreature)
  end
  for id, trackedPosition in pairs(trackedPositions) do
    signalcall(g_game.onTrackPosition, trackedPosition)
  end
end

--[[ Track Creatures ]]

function GameTracker.getTrackedCreatures()
  return trackedCreatures
end

function GameTracker.isTracked(creature)
  return trackedCreatures[creature:getId()] and true or false
end

function Creature:getTrackInfo()
  return trackedCreatures[self:getId()]
end

function GameTracker.sendTrackAction(creature, start)
  if not creature or creature:isRemoved() then
    return
  end
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeTracking)
  msg:addU8(start and TrackingInfo.Start or TrackingInfo.Stop)
  msg:addU32(creature:getId())
  protocolGame:send(msg)
end

function GameTracker.startTracking(creature)
  GameTracker.sendTrackAction(creature, true) 
end

function GameTracker.stopTracking(creature)
  GameTracker.sendTrackAction(creature, false)
end

function GameTracker.toggleTracking(creature)
  GameTracker.sendTrackAction(creature, not GameTracker.isTracked(creature))
end

function GameTracker.onTrackCreature(protocol, msg)
  local creatureId = msg:getU32()
  trackedCreatures[creatureId] = trackedCreatures[creatureId] or { color = '#ffc659' }

  local trackedCreature = trackedCreatures[creatureId]
  trackedCreature.id = creatureId
  trackedCreature.status = msg:getU8()

  while true do
    local flag = msg:getU8()
    if flag == TrackingInfo.Name then
      trackedCreature.name = msg:getString()
    elseif flag == TrackingInfo.Position then
      trackedCreature.position = protocol:getPosition(msg)
    elseif flag == TrackingInfo.Outfit then
      trackedCreature.outfit = protocol:getOutfit(msg)
    elseif flag == TrackingInfo.MsgEnd then
      break
    else
      print_r("Error flag " .. flag)
      break
    end
  end

  signalcall(g_game.onTrackCreature, trackedCreature)
  if trackedCreature.status == TrackingInfo.Stop then
    trackedCreatures[trackedCreature.id] = nil
  end
  return true
end

--[[ Track Position ]]
function GameTracker.getTrackedPositions()
  return trackedPositions
end

function GameTracker.isTrackedPosition(position)
  for _, posNode in pairs(trackedPositions) do
    if Position.equals(posNode.position, position) then
      return true
    end
  end
  return false
end

function GameTracker.getTrackedPosition(position)
  for _, posNode in pairs(trackedPositions) do
    if Position.equals(posNode.position, position) then
      return posNode
    end
  end
  return nil
end

function GameTracker.startTrackPosition(position)
  if GameTracker.isTrackedPosition(position) then
    return
  end
  local posNode = { index = posIndex, position = position, color = '#ffc659' }
  posIndex = posIndex + 1
  trackedPositions[posNode.index] = posNode
  signalcall(g_game.onTrackPosition, posNode)
end

function GameTracker.stopTrackPosition(position)
  local posNode = GameTracker.getTrackedPosition(position)
  if not posNode then
    return
  end
  signalcall(g_game.onTrackPositionEnd, posNode)
  trackedPositions[posNode.index] = nil
end

function GameTracker.createEditTrackWindow(trackNode)
  local trackerWindow = g_ui.displayUI('tracker')

  local red = trackerWindow:getChildById('red')
  local green = trackerWindow:getChildById('green')
  local blue = trackerWindow:getChildById('blue')

  local activeColor = tocolor(trackNode.color)
  red:setValue(activeColor.r)
  green:setValue(activeColor.g)
  blue:setValue(activeColor.b)

  local updateColor = function()
    local display = trackerWindow:getChildById('colorDisplay')
    display:setBackgroundColor({r = red:getValue(), g = green:getValue(), b = blue:getValue(), a = 255})
  end

  updateColor()

  local changeFunc = function()
    trackNode.color = colortostring({r = red:getValue(), g = green:getValue(), b = blue:getValue(), a = 255})
    signalcall(g_game.onUpdateTrackColor, trackNode)
    trackerWindow:destroy()
  end

  local cancelFunc = function()
    trackerWindow:destroy()
  end

  trackerWindow.onEnter = changeFunc
  trackerWindow.onEscape = cancelFunc

  local okButton = trackerWindow:getChildById('okButton')
  local cancelButton = trackerWindow:getChildById('cancelButton')

  okButton.onClick = changeFunc
  cancelButton.onClick = cancelFunc

  red.onValueChange = updateColor
  green.onValueChange = updateColor
  blue.onValueChange = updateColor

end
