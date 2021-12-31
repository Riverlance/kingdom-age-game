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
  trackedCreatures[creatureId] = trackedCreatures[creatureId] or { }

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
  for _, posNode in ipairs(trackedPositions) do
    if Position.equals(posNode.position, position) then
      return true
    end
  end
  return false
end

function GameTracker.startTrackPosition(position)
  if GameTracker.isTrackedPosition(position) then
    return
  end
  local posNode = { position = position }
  table.insert(trackedPositions, posNode)
  signalcall(g_game.onTrackPosition, posNode)
end