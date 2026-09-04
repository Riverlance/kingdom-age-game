CharacterList = {}
ClientCharacterList = CharacterList

-- private variables
local charactersWindow
local loadBox
local characterList
local errorBox
local waitingWindow
local updateWaitEvent
local resendWaitEvent
local loginEvent

-- private functions
local function tryLogin(charInfo, tries)
    tries = tries or 1

    if tries > 50 then
        return
    end

    if g_game.isOnline() then
        if tries == 1 then
            g_game.safeLogout()
			if loginEvent then
				removeEvent(loginEvent)
				loginEvent = nil
			end
        end
        loginEvent = scheduleEvent(function()
            tryLogin(charInfo, tries + 1)
        end, 100)
        return
    end

    CharacterList.hide()

    g_game.loginWorld(G.account, G.password, charInfo.worldName, charInfo.worldHost, charInfo.worldPort,
                      charInfo.characterName, G.authenticatorToken, G.sessionKey)

    loadBox = displayCancelBox(loc'${CorelibInfoLoading}', loc'${CharacterListConnectingMessage}')
    connect(loadBox, {
        onCancel = function()
            loadBox = nil
            g_game.cancelLogin()
            CharacterList.show()
        end
    })

    -- save last used character
    g_settings.set('last-used-character', charInfo.characterName)
    g_settings.set('last-used-world', charInfo.worldName)
end

local function updateWait(timeStart, timeEnd)
    if waitingWindow then
        local time = g_clock.seconds()
        if time <= timeEnd then
            local percent = ((time - timeStart) / (timeEnd - timeStart)) * 100
            local timeStr = f('%.0f', timeEnd - time)

            local progressBar = waitingWindow:getChildById('progressBar')
            progressBar:setPercent(percent)

            local label = waitingWindow:getChildById('timeLabel')
            label:setText(f(loc'${CharacterListWaitingListTimelabel}', timeStr))

            updateWaitEvent = scheduleEvent(function()
                updateWait(timeStart, timeEnd)
            end, 1000 * progressBar:getPercentPixels() / 100 * (timeEnd - timeStart))
            return true
        end
    end

    if updateWaitEvent then
        updateWaitEvent:cancel()
        updateWaitEvent = nil
    end
end

local function resendWait()
    if waitingWindow then
        waitingWindow:destroy()
        waitingWindow = nil

        if updateWaitEvent then
            updateWaitEvent:cancel()
            updateWaitEvent = nil
        end

        if charactersWindow then
            local selected = characterList:getFocusedChild()
            if selected then
                local charInfo = {
                    worldHost = selected.worldHost,
                    worldPort = selected.worldPort,
                    worldName = selected.worldName,
                    characterName = selected.characterName,
                    level = selected.level,
                    main = selected.main,
                    hidden = selected.hidden,
                    outfitid = selected.outfitid,
                    headcolor = selected.headcolor,
                    torsocolor = selected.torsocolor,
                    legscolor = selected.legscolor,
                    detailcolor = selected.detailcolor,
                    addonsflags = selected.addonsflags,
                    vocation = selected.vocation,
                    vocationId = selected.vocationId,
                    online = selected.online
                }
                tryLogin(charInfo)
            end
        end
    end
end

local function onLoginWait(message, time)
    CharacterList.destroyLoadBox()

    waitingWindow = g_ui.displayUI('waitinglist')

    local label = waitingWindow:getChildById('infoLabel')
    label:setText(message)

    updateWaitEvent = scheduleEvent(function()
        updateWait(g_clock.seconds(), g_clock.seconds() + time)
    end, 0)
    resendWaitEvent = scheduleEvent(resendWait, time * 1000)
end

function onGameLoginError(message)
    CharacterList.destroyLoadBox()
    errorBox = displayErrorBox(loc'${CharacterListLoginErrorTitle}', message)
    errorBox.onOk = function()
        errorBox = nil
        CharacterList.showAgain()
    end
end

function onGameLoginToken(unknown)
    CharacterList.destroyLoadBox()
    errorBox = displayErrorBox(loc'${CharacterListLoginTokenTitle}', loc'${CharacterListLoginTokenMessage}')
    errorBox.onOk = function()
        errorBox = nil
        ClientEnterGame.show()
    end
end

function onGameConnectionError(message, code)
    CharacterList.destroyLoadBox()
    local text = translateNetworkError(code, g_game.getProtocolGame() and g_game.getProtocolGame():isConnecting(),
                                       message)
    errorBox = displayErrorBox(loc'${CharacterListConnectionErrorTitle}', text)
    errorBox.onOk = function()
        errorBox = nil
        CharacterList.showAgain()
    end
end

function onGameUpdateNeeded(signature)
    CharacterList.destroyLoadBox()
    errorBox = displayErrorBox(loc'${CharacterListUpdateNeededTitle}', loc'${CharacterListUpdateNeededMessage}')
    errorBox.onOk = function()
        errorBox = nil
        CharacterList.showAgain()
    end
end

function CharacterList.getCharacterInfoByName(name)
    if not G.characters or not name then
        return nil
    end

    for _, characterInfo in ipairs(G.characters) do
        if characterInfo.name and characterInfo.name:lower() == name:lower() then
            return characterInfo
        end
    end

    return nil
end

function CharacterList.updateCharacterInfo(online)
    if not characterList then
        return
    end

    local localPlayer = g_game.getLocalPlayer()
    local characterName = localPlayer and localPlayer:getName() or g_game.getCharacterName()
    if not characterName or characterName == '' then
        return
    end

    local characterWidget
    for _, widget in ipairs(characterList:getChildren()) do
        if widget.characterName and widget.characterName:lower() == characterName:lower() then
            characterWidget = widget
            break
        end
    end

    if not characterWidget then
        return
    end

    if online == nil then
        online = g_game.isOnline()
    end

    local characterInfo = CharacterList.getCharacterInfoByName(characterName)
    if localPlayer then
        local level = localPlayer:getLevel()
        local vocationId = localPlayer:getVocation()
        local outfit = localPlayer:getOutfit()
        local vocation = VocationStr[vocationId] or tostring(vocationId)

        characterWidget.level = level
        characterWidget.vocationId = vocationId
        characterWidget.vocation = vocation

        if characterInfo then
            characterInfo.level = level
            characterInfo.vocationId = vocationId
            characterInfo.vocation = vocation
        end

        local levelWidget = characterWidget:getChildById('level')
        if levelWidget then
            levelWidget:setText(tostring(level))
        end

        local vocationWidget = characterWidget:getChildById('vocation')
        if vocationWidget then
            vocationWidget:setText(vocation)
        end

        local creatureDisplay = characterWidget:getChildById('outfitCreatureBox')
        if creatureDisplay and outfit and outfit.type and outfit.type > 0 then
            creatureDisplay:setOutfit(outfit)
        end

        if characterInfo and outfit then
            characterInfo.outfitid = outfit.type
            characterInfo.headcolor = outfit.head
            characterInfo.torsocolor = outfit.body
            characterInfo.legscolor = outfit.legs
            characterInfo.detailcolor = outfit.feet
            characterInfo.addonsflags = outfit.addons
        end
    end

    characterWidget.online = online
    if characterInfo then
        characterInfo.online = online
    end

    local statusWidget = characterWidget:getChildById('status')
    if statusWidget then
        statusWidget:setText(online and loc'${CharacterListStatusOnline}' or loc'${CharacterListStatusOffline}')
        statusWidget:setColor(online and tocolor('green') or tocolor('darkRed'))
    end
end

function CharacterList.onGameStart()
    CharacterList.destroyLoadBox()
    CharacterList.updateCharacterInfo(true)
end

function CharacterList.onEnterGame()
    CharacterList.updateCharacterInfo(true)
end

function CharacterList.onGameEnd()
    CharacterList.updateCharacterInfo(false)
    CharacterList.showAgain()
end

function CharacterList.onOutfitChange(localPlayer)
    if localPlayer == g_game.getLocalPlayer() then
        CharacterList.updateCharacterInfo()
    end
end

function CharacterList.onLevelChange(localPlayer)
    if localPlayer == g_game.getLocalPlayer() then
        CharacterList.updateCharacterInfo()
    end
end

function CharacterList.onVocationChange(localPlayer)
    if localPlayer == g_game.getLocalPlayer() then
        CharacterList.updateCharacterInfo()
    end
end

-- public functions
function CharacterList.init()
    connect(g_game, {
        onLoginError = onGameLoginError,
        onLoginToken = onGameLoginToken
    })
    connect(g_game, {
        onUpdateNeeded = onGameUpdateNeeded
    })
    connect(g_game, {
        onConnectionError = onGameConnectionError
    })
    connect(g_game, {
        onGameStart = CharacterList.onGameStart,
        onEnterGame = CharacterList.onEnterGame
    })
    connect(g_game, {
        onLoginWait = onLoginWait
    })
    connect(g_game, {
        onGameEnd = CharacterList.onGameEnd
    })
    connect(g_game, {
        onLoginnameChange = CharacterList.updateLoginname
    })
    connect(LocalPlayer, {
        onOutfitChange = CharacterList.onOutfitChange,
        onLevelChange = CharacterList.onLevelChange,
        onVocationChange = CharacterList.onVocationChange
    })
    ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeAccountInfo,
        CharacterList.parseCharacterList)

    if G.characters then
        CharacterList.create(G.characters, G.characterAccount)
    end
end

function CharacterList.terminate()
    disconnect(g_game, {
        onLoginError = onGameLoginError,
        onLoginToken = onGameLoginToken
    })
    disconnect(g_game, {
        onUpdateNeeded = onGameUpdateNeeded
    })
    disconnect(g_game, {
        onConnectionError = onGameConnectionError
    })
    disconnect(g_game, {
        onGameStart = CharacterList.onGameStart,
        onEnterGame = CharacterList.onEnterGame
    })
    disconnect(g_game, {
        onLoginWait = onLoginWait
    })
    disconnect(g_game, {
        onGameEnd = CharacterList.onGameEnd
    })
    disconnect(g_game, {
        onLoginnameChange = CharacterList.updateLoginname
    })
    disconnect(LocalPlayer, {
        onOutfitChange = CharacterList.onOutfitChange,
        onLevelChange = CharacterList.onLevelChange,
        onVocationChange = CharacterList.onVocationChange
    })
    ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeAccountInfo)

    if charactersWindow then
        characterList = nil
        charactersWindow:destroy()
        charactersWindow = nil
    end

    if loadBox then
        g_game.cancelLogin()
        loadBox:destroy()
        loadBox = nil
    end

    if waitingWindow then
        waitingWindow:destroy()
        waitingWindow = nil
    end

    if updateWaitEvent then
        removeEvent(updateWaitEvent)
        updateWaitEvent = nil
    end

    if resendWaitEvent then
        removeEvent(resendWaitEvent)
        resendWaitEvent = nil
    end

    if loginEvent then
        removeEvent(loginEvent)
        loginEvent = nil
    end

    CharacterList = nil
    ClientCharacterList = nil
end

function CharacterList.create(characters, account, otui)
    if not otui then
        otui = 'characterlist'
    end

    if charactersWindow then
        charactersWindow:destroy()
    end

    charactersWindow = g_ui.displayUI(otui)
    characterList = charactersWindow:getChildById('characterData')

    -- characters
    G.characters = characters
    G.characterAccount = account

    characterList:destroyChildren()
    local accountStatusLabel = charactersWindow:getChildById('accountStatusLabel')
    local accountStatusIcon = nil
    if g_game.getFeature(GameEnterGameShowAppearance) then
        accountStatusIcon = charactersWindow:getChildById('accountStatusIcon')
    end

    local focusLabel
    for i, characterInfo in ipairs(characters) do
        local widget = g_ui.createWidget('CharacterWidget', characterList)
        for key, value in pairs(characterInfo) do
            local subWidget = widget:getChildById(key)
            if subWidget then
                if key == 'outfit' then -- it's an exception
                    subWidget:setOutfit(value)
                else
                    local text = type(value) == 'string' and value or tostring(value)
                    if subWidget.baseText then
                        text = f(subWidget.baseText, text)
                    end
                    subWidget:setText(text)
                end
            end
        end

        local nameWidget = widget:getChildById('name')
        if nameWidget and characterInfo.loginname and characterInfo.loginname ~= '' then
            nameWidget:setText(characterInfo.loginname)
        end

        if g_game.getFeature(GameEnterGameShowAppearance) then
            local creatureDisplay = widget:getChildById('outfitCreatureBox')
            if creatureDisplay and characterInfo.outfitid then
                local outfit = {type = characterInfo.outfitid, auxType = 0, head = characterInfo.headcolor or 0, body = characterInfo.torsocolor or 0, legs = characterInfo.legscolor or 0, feet = characterInfo.detailcolor or 0, addons = characterInfo.addonsflags or 0, mount = 0}
                creatureDisplay:setOutfit(outfit)
            end

            local mainCharacter = widget:getChildById('mainCharacter')
            if characterInfo.main then
                mainCharacter:setImageSource('/images/ui/enter_game/maincharacter')
            else
                mainCharacter:setImageSource('')
            end

            local statusHidden = widget:getChildById('statusHidden')
            if characterInfo.hidden then
                statusHidden:setImageSource('/images/ui/enter_game/hidden')
            else
                statusHidden:setImageSource('')
            end
        end

        -- these are used by login
        widget.characterName = characterInfo.name
        widget.name = characterInfo.name
        widget.loginname = characterInfo.loginname or ''
        widget.worldName = characterInfo.worldName
        widget.worldHost = characterInfo.worldIp
        widget.worldPort = characterInfo.worldPort

        local statusWidget = widget:getChildById('status')
        if statusWidget then
            statusWidget:setText(characterInfo.online and loc'${CharacterListStatusOnline}' or loc'${CharacterListStatusOffline}')
            statusWidget:setColor(characterInfo.online and tocolor('green') or tocolor('darkRed'))
        end

        connect(widget, {
            onDoubleClick = function()
                CharacterList.doLogin()
                return true
            end
        })

        if i == 1 or
            (g_settings.get('last-used-character') == widget.characterName and g_settings.get('last-used-world') ==
                widget.worldName) then
            focusLabel = widget
        end
    end

    if focusLabel then
        characterList:focusChild(focusLabel, KeyboardFocusReason)
        local focusLabelId = focusLabel:getId()
        addEvent(withWeakWidget(characterList, function(widget)
            local focusedWidget = widget:getChildById(focusLabelId)
            if focusedWidget then
                widget:ensureChildVisible(focusedWidget)
            end
        end))
    end

    -- account
    if account.premDays == 0 then
        accountStatusLabel:setText(loc'${CharacterListAccountStatusValueFree}')
        if accountStatusIcon ~= nil then
            accountStatusIcon:setImageSource('/images/ui/enter_game/nopremium')
        end
    else
        if account.premDays == 65535 then
            accountStatusLabel:setText(loc'${CharacterListAccountStatusValuePremiumLifetime}')
        else
            accountStatusLabel:setText(f('%s: %d', loc'${CharacterListAccountStatusValuePremium} - ${CharacterListAccountStatusValuePremiumDaysLeft}', account.premDays))
        end
        if accountStatusIcon ~= nil then
            accountStatusIcon:setImageSource('/images/ui/enter_game/premium')
        end
    end

    if account.premDays > 0 and account.premDays <= 7 then
        accountStatusLabel:setOn(true)
    else
        accountStatusLabel:setOn(false)
    end
end

function CharacterList.destroy()
    CharacterList.hide(true)

    if charactersWindow then
        characterList = nil
        charactersWindow:destroy()
        charactersWindow = nil
    end
end

function CharacterList.show()
    if loadBox or errorBox or not charactersWindow then
        return
    end
    charactersWindow:show()
    charactersWindow:raise()
    charactersWindow:focus()
    if ClientEnterGame then
        ClientEnterGame.toggleLoginButton(true)
    end
end

function CharacterList.hide(showLogin)
    showLogin = showLogin or false
    if not charactersWindow then
        return
    end

    charactersWindow:hide()
    if ClientEnterGame then
        ClientEnterGame.toggleLoginButton(false)
    end

    if showLogin and not g_game.isOnline() then
        if ClientEnterGame then
            ClientEnterGame.show()
        end
    end
end

function CharacterList.showAgain()
    if characterList and characterList:hasChildren() then
        CharacterList.show()
    end
end

function CharacterList.isVisible()
    if charactersWindow and charactersWindow:isVisible() then
        return true
    end
    return false
end

function CharacterList.doLogin()
    local selected = characterList:getFocusedChild()
    if selected then
        local charInfo = {
            worldHost = selected.worldHost,
            worldPort = selected.worldPort,
            worldName = selected.worldName,
            characterName = selected.characterName
        }
        charactersWindow:hide()
        if loginEvent then
            removeEvent(loginEvent)
            loginEvent = nil
        end
        tryLogin(charInfo)
    else
        displayErrorBox(loc'${CorelibInfoError}', loc'${CharacterListCharSelectionErrorMessage}')
    end
end

function CharacterList.destroyLoadBox()
    if loadBox then
        loadBox:destroy()
        loadBox = nil
    end
end

function CharacterList.cancelWait()
    if waitingWindow then
        waitingWindow:destroy()
        waitingWindow = nil
    end

    if updateWaitEvent then
        removeEvent(updateWaitEvent)
        updateWaitEvent = nil
    end

    if resendWaitEvent then
        removeEvent(resendWaitEvent)
        resendWaitEvent = nil
    end

    CharacterList.destroyLoadBox()
    CharacterList.showAgain()
end

function CharacterList.updateLoginname(name, currentLoginname, newLoginname)
    if not characterList then
        return
    end

    for _, widget in ipairs(characterList:getChildren()) do
        if widget.name and widget.loginname and widget.name:lower() == name:lower() and
            widget.loginname:lower() == currentLoginname:lower() then
            widget.loginname = newLoginname
            local nameWidget = widget:getChildById('name')
            if nameWidget then
                nameWidget:setText(newLoginname == '' and widget.name or newLoginname)
            end
        end
    end
end

function CharacterList.parseCharacterList(protocolGame, opcode, msg)
    local worlds = {}
    local characters = {}
    local worldsCount = msg:getU8()
    for _ = 1, worldsCount do
        local world = {}
        local worldId = msg:getU8()
        world.worldName = msg:getString()
        world.worldIp = msg:getString()
        world.worldPort = msg:getU16()
        world.previewState = msg:getU8()
        worlds[worldId] = world
    end

    local charactersCount = msg:getU8()
    for i = 1, charactersCount do
        local character = {}
        local worldId = msg:getU8()
        character.worldId = worldId
        character.name = msg:getString()
        character.loginname = msg:getString()
        if g_game.getFeature(GameEnterGameShowAppearance) then
            character.level = msg:getU32()
            character.vocationId = msg:getU16()
            character.vocation = VocationStr[character.vocationId] or tostring(character.vocationId)
            character.outfitid = msg:getU16()
            character.headcolor = msg:getU8()
            character.torsocolor = msg:getU8()
            character.legscolor = msg:getU8()
            character.detailcolor = msg:getU8()
            character.addonsflags = msg:getU8()
            character.online = msg:getU8() ~= 0
        end
        local world = worlds[worldId]
        if world then
            character.worldName = world.worldName
            character.worldIp = world.worldIp
            character.worldPort = world.worldPort
            character.previewState = world.previewState
        end
        characters[i] = character
    end

    local account = {premDays = msg:getU16()}
    CharacterList.create(characters, account)
end
