local smartWalkDirs = {}
local smartWalkDir = nil
local walkEvent = nil
local lastTurn = 0
local lastCancelWalkTime = 0
local nextWalkDir = nil

local function mapWalkDirectionByCurrentView(dir)
    local gameMapPanel = GameInterface.getMapPanel()
    if not gameMapPanel or not gameMapPanel.isTransposedView or not gameMapPanel:isTransposedView() then
        return dir
    end

    return Position.transposeDirection(dir)
end

function init()
    connect(g_game, {
        onGameStart = onGameStart,
        onTeleport = onTeleport,
    })
    connect(LocalPlayer, {
        onCancelWalk = onCancelWalk,
        onWalkFinish = onWalkFinish,
    })

    bindKeys()
end

function terminate()
    disconnect(g_game, {
        onGameStart = onGameStart,
        onTeleport = onTeleport,
    })
    disconnect(LocalPlayer, {
        onCancelWalk = onCancelWalk,
        onWalkFinish = onWalkFinish,
    })

    stopSmartWalk()

    for _, key in ipairs({'Up', 'Right', 'Down', 'Left', 'Numpad8', 'Numpad9', 'Numpad6', 'Numpad3', 'Numpad2', 'Numpad1', 'Numpad4', 'Numpad7'}) do
        unbindWalkKey(key)
    end

    for _, key in ipairs({'Ctrl+Up', 'Ctrl+Right', 'Ctrl+Down', 'Ctrl+Left', 'Ctrl+Numpad8', 'Ctrl+Numpad6', 'Ctrl+Numpad2', 'Ctrl+Numpad4'}) do
        unbindTurnKey(key)
    end
end

function onGameStart()
    GameInterface.getRootPanel().onFocusChange = stopSmartWalk

    -- Open Tibia has a delay in auto walking.
    if not g_game.isOfficialTibia() then
        g_game.enableFeature(GameForceFirstAutoWalkStep)
    else
        g_game.disableFeature(GameForceFirstAutoWalkStep)
    end
end

function bindKeys()
    GameInterface.getRootPanel():setAutoRepeatDelay(200)

    bindWalkKey('Up', North)
    bindWalkKey('Right', East)
    bindWalkKey('Down', South)
    bindWalkKey('Left', West)
    bindWalkKey('Numpad8', North)
    bindWalkKey('Numpad9', NorthEast)
    bindWalkKey('Numpad6', East)
    bindWalkKey('Numpad3', SouthEast)
    bindWalkKey('Numpad2', South)
    bindWalkKey('Numpad1', SouthWest)
    bindWalkKey('Numpad4', West)
    bindWalkKey('Numpad7', NorthWest)

    bindTurnKey('Ctrl+Up', North)
    bindTurnKey('Ctrl+Right', East)
    bindTurnKey('Ctrl+Down', South)
    bindTurnKey('Ctrl+Left', West)
    bindTurnKey('Ctrl+Numpad8', North)
    bindTurnKey('Ctrl+Numpad6', East)
    bindTurnKey('Ctrl+Numpad2', South)
    bindTurnKey('Ctrl+Numpad4', West)
end

function bindWalkKey(key, dir)
    local gameRootPanel = GameInterface.getRootPanel()
    g_keyboard.bindKeyDown(key, function()
        g_keyboard.setKeyDelay(key, 1)
        changeWalkDir(dir)
    end, gameRootPanel, true)
    g_keyboard.bindKeyUp(key, function()
        g_keyboard.setKeyDelay(key, 30)
        changeWalkDir(dir, true)
    end, gameRootPanel, true)
    g_keyboard.bindKeyPress(key, function(_, _, ticks)
        smartWalk(dir, ticks)
    end, gameRootPanel)
end

function unbindWalkKey(key)
    local gameRootPanel = GameInterface.getRootPanel()
    g_keyboard.unbindKeyDown(key, gameRootPanel)
    g_keyboard.unbindKeyUp(key, gameRootPanel)
    g_keyboard.unbindKeyPress(key, gameRootPanel)
end

function bindTurnKey(key, dir, checkConsole)
    local gameRootPanel = GameInterface.getRootPanel()
    g_keyboard.bindKeyDown(key, function()
        if checkConsole and GameConsole and GameConsole.isChatEnabled() then
            return
        end
        turn(dir, false)
    end, gameRootPanel)
    g_keyboard.bindKeyPress(key, function()
        if checkConsole and GameConsole and GameConsole.isChatEnabled() then
            return
        end
        turn(dir, true)
    end, gameRootPanel)
    g_keyboard.bindKeyUp(key, function()
        if checkConsole and GameConsole and GameConsole.isChatEnabled() then
            return
        end
        local player = g_game.getLocalPlayer()
        if player then
            player:lockWalk(200)
        end
    end, gameRootPanel)
end

function unbindTurnKey(key)
    local gameRootPanel = GameInterface.getRootPanel()
    g_keyboard.unbindKeyDown(key, gameRootPanel)
    g_keyboard.unbindKeyPress(key, gameRootPanel)
    g_keyboard.unbindKeyUp(key, gameRootPanel)
end

function stopSmartWalk()
    cancelWalkEvent()
    smartWalkDirs = {}
    smartWalkDir = nil
end

function changeWalkDir(dir, pop)
    dir = mapWalkDirectionByCurrentView(dir)

    while table.removevalue(smartWalkDirs, dir) do end
    if pop then
        if #smartWalkDirs == 0 then
            stopSmartWalk()
            return
        end
    else
        table.insert(smartWalkDirs, 1, dir)
    end

    smartWalkDir = smartWalkDirs[1]
    if ClientOptions.getOption('smartWalk') and #smartWalkDirs > 1 then
        for _, d in pairs(smartWalkDirs) do
            if (smartWalkDir == North and d == West) or (smartWalkDir == West and d == North) then
                smartWalkDir = NorthWest
                break
            elseif (smartWalkDir == North and d == East) or (smartWalkDir == East and d == North) then
                smartWalkDir = NorthEast
                break
            elseif (smartWalkDir == South and d == West) or (smartWalkDir == West and d == South) then
                smartWalkDir = SouthWest
                break
            elseif (smartWalkDir == South and d == East) or (smartWalkDir == East and d == South) then
                smartWalkDir = SouthEast
                break
            end
        end
    end
end

function smartWalk(dir)
    addWalkEvent(smartWalkDir or mapWalkDirectionByCurrentView(dir))
end

function walk(dir)
    local player = g_game.getLocalPlayer()
    if not player or g_game.isDead() or player:isDead() then
        return
    end

    if player:isWalkLocked() then
        cancelWalkEvent()
        return
    end

    if g_game.isFollowing() then
        g_game.cancelFollow()
    end

    if player:isAutoWalking() or player:isServerWalking() then
        g_game.stop()
        if player:isAutoWalking() then
            player:stopAutoWalk()
        end
        player:lockWalk(player:getStepDuration() + 50)
        return
    end

    if not player:canWalk() then
        nextWalkDir = dir
        return
    end

    nextWalkDir = nil

    if g_game.getFeature(GameAllowPreWalk) then
        local toPos = Position.translatedToDirection(player:getPosition(), dir)
        local toTile = g_map.getTile(toPos)

        -- KA - Ghost mode walking
        local isInGhostMode = player:isInGhostMode()

        if toTile and (toTile:isWalkable() or isInGhostMode) then
            player:preWalk(dir)
        elseif canChangeFloorDown(toPos) or canChangeFloorUp(toPos) then
            player:preWalk(dir)
        else
            -- KA - Turn to unwalkable direction
            if not isInGhostMode and toTile and not toTile:isEmpty() then
                g_game.turn(dir)
            end

            -- KA - Removed possibility to walk to higher/lower floor by items that have elevation.
            -- Floor changes are handled explicitly by canChangeFloorDown() and canChangeFloorUp().
            return false
        end
    end

    modules.game_interface.lastManualWalk = g_clock.millis()
    g_game.walk(dir)
    return true
end

function turn(dir, repeated)
    local player = g_game.getLocalPlayer()
    local mappedDir = mapWalkDirectionByCurrentView(dir)
    if not player or (player:isWalking() and player:getDirection() == mappedDir) then
        return
    end

    cancelWalkEvent()

    local delay = repeated and 150 or 50
    if lastTurn + delay < g_clock.millis() then
        g_game.turn(mappedDir)
        changeWalkDir(dir)
        lastTurn = g_clock.millis()
        player:lockWalk(g_settings.getNumber('walkTurnDelay'))
    end
end

local function canChangeFloor(pos, deltaZ)
    if deltaZ == 0 then
        return false
    end

    local toPos = {x = pos.x, y = pos.y, z = pos.z + deltaZ}
    local toTile = g_map.getTile(toPos)
    if not toTile then
        return false
    end

    if deltaZ > 0 then
        -- Floor changes are handled by floor-change tiles. This client does
        -- not support changing floors through three or more elevated items
        -- on the same tile (for example, stacked parcels).
        return toTile:isWalkable() and toTile:hasFloorChange()
    elseif deltaZ < 0 then
        return toTile:isWalkable()
    end

    return false
end

function canChangeFloorDown(pos)
    return canChangeFloor(pos, 1)
end

function canChangeFloorUp(pos)
    return canChangeFloor(pos, -1)
end

function addWalkEvent(dir, delay)
    if g_clock.millis() - lastCancelWalkTime > 20 then
        cancelWalkEvent()
        lastCancelWalkTime = g_clock.millis()
    end

    local function walkCallback()
        if g_keyboard.getModifiers() ~= KeyboardNoModifier then
            return
        end

        local direction = smartWalkDir or dir
        walk(direction)
    end

    if delay and delay > 0 then
        walkEvent = scheduleEvent(walkCallback, delay)
    else
        walkEvent = addEvent(walkCallback)
    end
end

function cancelWalkEvent()
    if walkEvent then
        removeEvent(walkEvent)
        walkEvent = nil
    end

    nextWalkDir = nil
end

-- Events
function onTeleport(player, newPos, oldPos)
    if not newPos or not oldPos then
        return
    end

    if Position.offsetX(newPos, oldPos) >= 3 or Position.offsetY(newPos, oldPos) >= 3 or Position.offsetZ(newPos, oldPos) >= 2 then
        player:lockWalk(g_settings.getNumber('walkTeleportDelay'))
    else
        player:lockWalk(g_settings.getNumber('walkStairsDelay'))
    end
end

function onWalkFinish(player)
    if nextWalkDir then
        if not g_game.getFeature(GameAllowPreWalk) then
            walk(nextWalkDir)
        else
            addWalkEvent(nextWalkDir, 50)
        end
    end
end

function onCancelWalk(player)
    player:lockWalk(50)
end
