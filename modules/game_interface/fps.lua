local fpsLabel
local pingLabel

local lastSyncValue = -1
local fpsEvent = nil
local fpsMin = -1
local fpsMax = -1
local lastFps = nil
local lastPing = nil

local function resetFpsAndUpdatePingVisibility()
  fpsMin = -1
  GameInterface.updatePingVisibility()
end


function GameInterface.initFps()
  connect(g_app, {
    onFps = GameInterface.updateFps,
  })

  connect(g_game, {
    onGameStart = GameInterface.updatePingVisibility,
    onGameEnd   = resetFpsAndUpdatePingVisibility,
    onPingBack  = GameInterface.updatePing,
  })
end

function GameInterface.terminateFps()
  disconnect(g_app, {
    onFps = GameInterface.updateFps,
  })

  disconnect(g_game, {
    onGameStart = GameInterface.updatePingVisibility,
    onGameEnd   = resetFpsAndUpdatePingVisibility,
    onPingBack  = GameInterface.updatePing,
  })
end

function GameInterface.setFpsLabelWidget(widget)
  fpsLabel = widget
  if not fpsLabel then
    return
  end

  GameInterface.setFpsVisible(ClientOptions.getOption('showFps') ~= false)
end

function GameInterface.setPingLabelWidget(widget)
  pingLabel = widget
  if not pingLabel then
    return
  end

  GameInterface.updatePingVisibility()
  if lastPing ~= nil then
    GameInterface.updatePing(lastPing)
  end
end

function GameInterface.setFpsVisible(visible)
  if not fpsLabel then
    return
  end

  fpsLabel:setVisible(visible)
  if visible and lastFps ~= nil then
    GameInterface.updateFps(lastFps)
  end
end

function GameInterface.setPingVisible(visible)
  if not pingLabel then
    return
  end

  pingLabel:setVisible(visible)
  if visible and lastPing ~= nil then
    GameInterface.updatePing(lastPing)
  end
end

function GameInterface.updatePingVisibility()
  if not pingLabel then
    return
  end

  local visible = g_game.isOnline() and ClientOptions.getOption('showPing') and g_game.getFeature(GameClientPing)
  pingLabel:setVisible(not not visible)
end

function GameInterface.updateFps(fps)
  lastFps = fps
  if not fpsLabel or not fpsLabel:isVisible() then
    return
  end

  local text = f(loc'${ClientTopMenuFps}: %s', fps)

  if g_game.isOnline() then
    local vsync = ClientOptions.getOption('vsync')
    if fpsEvent == nil and lastSyncValue ~= vsync then
      fpsEvent = addEvent(function()
        fpsMin = -1
        lastSyncValue = vsync
        fpsEvent = nil
      end, 2000)
    end

    if fpsMin == -1 then
      fpsMin = fps
      fpsMax = fps
    end

    if fps > fpsMax then
      fpsMax = fps
    end

    if fps < fpsMin then
      fpsMin = fps
    end

    local midFps = math.floor((fpsMin + fpsMax) / 2)
    fpsLabel:setTooltip(f(loc'${ClientTopMenuFpsTooltip}', fpsMin, midFps, fpsMax))
  else
    fpsLabel:removeTooltip()
  end

  fpsLabel:setText(text)
end

function GameInterface.updatePing(ping) -- See UICreatureButton:updatePing
  lastPing = ping
  if not pingLabel or not pingLabel:isVisible() then
    return
  end

  local text
  local color

  -- Unknown
  if ping < 0 then
    text  = loc'${ClientTopMenuFpsInfoPing}: ?'
    color = 'yellow'

  -- Known
  else
    text = f(loc'${ClientTopMenuFpsInfoPing}: %d ${CorelibInfoMs}', ping)

    if ping >= 500 then
      color = 'red'

    elseif ping >= 250 then
      color = 'yellow'

    else
      color = 'green'
    end
  end

  pingLabel:setText(text)
  pingLabel:setColor(color)
end
