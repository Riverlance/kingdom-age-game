local function onGameStart()
    -- local player = g_game.getLocalPlayer()
    -- player:attachPaperdoll(g_paperdolls.getById(1))
    -- player:attachPaperdoll(g_paperdolls.getById(2))
    -- player:attachPaperdoll(g_paperdolls.getById(3))
    -- player:attachPaperdoll(g_paperdolls.getById(4))
end

local function onGameEnd()
    local player = g_game.getLocalPlayer()
    if player then
        player:clearPaperdolls()
    end
end

local function onTerminate()
    g_paperdolls.clear()
end

local function onAttach(paperdoll, owner)
    local outfitType = owner:getOutfit().type
    local config = PaperdollManager.getConfig(paperdoll:getId(), outfitType)

    if config.isThingConfig then
        PaperdollManager.executeThingConfig(paperdoll, outfitType)
    end

    if config.onAttach then
        config.onAttach(paperdoll, owner, config.__onAttach)
    end
end

local function onDetach(paperdoll, oldOwner)
    local config = PaperdollManager.getConfig(paperdoll:getId(), oldOwner:getOutfit().type)

    if config.onDetach then
        config.onDetach(paperdoll, oldOwner, config.__onDetach)
    end
end

local function onOutfitChange(creature, outfit, oldOutfit)
    for _i, paperdoll in pairs(creature:getPaperdolls()) do
        PaperdollManager.executeThingConfig(paperdoll, outfit.type)
    end
end

function init()
    connect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = onGameEnd
    })
    connect(LocalPlayer, {
        onOutfitChange = onOutfitChange
    })
    connect(Creature, {
        onOutfitChange = onOutfitChange
    })
    connect(Paperdoll, {
        onAttach = onAttach,
        onDetach = onDetach
    })
end

function terminate()
    disconnect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = onGameEnd
    })
    disconnect(LocalPlayer, {
        onOutfitChange = onOutfitChange
    })
    disconnect(Creature, {
        onOutfitChange = onOutfitChange
    })
    disconnect(Paperdoll, {
        onAttach = onAttach,
        onDetach = onDetach
    })
    onTerminate()
end
