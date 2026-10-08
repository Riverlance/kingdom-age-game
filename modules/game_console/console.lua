g_locales.loadLocales(resolvepath(''))

_G.GameConsole = { }



NpcChannelName = 'NPCs' -- Do not translate it!



SpeakTypesSettings = {
  none = { },

  say = { speakType = MessageModes.Say, color = '#E0E000' },
  whisper = { speakType = MessageModes.Whisper, color = '#E0E0E0' },
  yell = { speakType = MessageModes.Yell, color = '#FFAA00' },

  private = { speakType = MessageModes.PrivateTo, color = '#5FF7F7', private = true },
  privateRed = { speakType = MessageModes.GamemasterPrivateTo, color = '#F55E5E', private = true },
  privatePlayerToPlayer = { speakType = MessageModes.PrivateTo, color = '#9F9DFD', private = true },
  privatePlayerToNpc = { speakType = MessageModes.NpcTo, color = '#9F9DFD', private = true, npcChat = true },
  privateNpcToPlayer = { speakType = MessageModes.NpcFrom, color = '#5FF7F7', private = true, npcChat = true },

  channelYellow = { speakType = MessageModes.Channel, color = '#E0E000' },
  channelWhite = { speakType = MessageModes.ChannelManagement, color = '#FFFFFF' },
  channelRed = { speakType = MessageModes.GamemasterChannel, color = '#F55E5E' },
  channelOrange = { speakType = MessageModes.ChannelHighlight, color = '#FE6500' },

  broadcast = { speakType = MessageModes.GamemasterBroadcast, color = '#F55E5E' },

  barkLow = { speakType = MessageModes.BarkLow, color = '#FE6500', hideInConsole = true},
  barkLoud = { speakType = MessageModes.BarkLoud, color = '#FE6500', hideInConsole = true},

  gamemasterSay = { speakType = MessageModes.GamemasterSay, color = '#A144FF' },
}

SpeakTypes = {
  [MessageModes.Say] = SpeakTypesSettings.say,
  [MessageModes.Whisper] = SpeakTypesSettings.whisper,
  [MessageModes.Yell] = SpeakTypesSettings.yell,

  [MessageModes.PrivateFrom] = SpeakTypesSettings.private,
  [MessageModes.PrivateTo] = SpeakTypesSettings.private,

  [MessageModes.ChannelManagement] = SpeakTypesSettings.channelWhite,
  [MessageModes.Channel] = SpeakTypesSettings.channelYellow,
  [MessageModes.ChannelHighlight] = SpeakTypesSettings.channelOrange,

  [MessageModes.Spell] = SpeakTypesSettings.none, -- ignored

  [MessageModes.NpcFromStartBlock] = SpeakTypesSettings.privateNpcToPlayer,
  [MessageModes.NpcFrom] = SpeakTypesSettings.privateNpcToPlayer,
  [MessageModes.NpcTo] = SpeakTypesSettings.privatePlayerToNpc,

  [MessageModes.GamemasterBroadcast] = SpeakTypesSettings.broadcast,
  [MessageModes.GamemasterChannel] = SpeakTypesSettings.channelRed,
  [MessageModes.GamemasterPrivateFrom] = SpeakTypesSettings.privateRed,
  [MessageModes.GamemasterPrivateTo] = SpeakTypesSettings.privateRed,

  [MessageModes.Login] = SpeakTypesSettings.none, -- ignored
  [MessageModes.Warning] = SpeakTypesSettings.none, -- ignored
  [MessageModes.Game] = SpeakTypesSettings.none, -- ignored
  [MessageModes.GameHighlight] = SpeakTypesSettings.none, -- ignored
  [MessageModes.Failure] = SpeakTypesSettings.none, -- ignored
  [MessageModes.Look] = SpeakTypesSettings.none, -- ignored

  [MessageModes.DamageDealed] = SpeakTypesSettings.none, -- ignored
  [MessageModes.DamageReceived] = SpeakTypesSettings.none, -- ignored
  [MessageModes.Heal] = SpeakTypesSettings.none, -- ignored
  [MessageModes.Exp] = SpeakTypesSettings.none, -- ignored
  [MessageModes.DamageOthers] = SpeakTypesSettings.none, -- ignored
  [MessageModes.HealOthers] = SpeakTypesSettings.none, -- ignored
  [MessageModes.ExpOthers] = SpeakTypesSettings.none, -- ignored

  [MessageModes.Status] = SpeakTypesSettings.none, -- ignored
  [MessageModes.Loot] = SpeakTypesSettings.none, -- ignored
  [MessageModes.TradeNpc] = SpeakTypesSettings.none, -- ignored
  [MessageModes.Guild] = SpeakTypesSettings.none, -- ignored

  [MessageModes.PartyManagement] = SpeakTypesSettings.none, -- ignored
  [MessageModes.Party] = SpeakTypesSettings.none, -- ignored

  [MessageModes.BarkLow] = SpeakTypesSettings.barkLow,
  [MessageModes.BarkLoud] = SpeakTypesSettings.barkLoud,

  [MessageModes.Report] = SpeakTypesSettings.none, -- ignored
  [MessageModes.HotkeyUse] = SpeakTypesSettings.none, -- ignored
  [MessageModes.TutorialHint] = SpeakTypesSettings.none, -- ignored

  [MessageModes.GamemasterSay] = SpeakTypesSettings.gamemasterSay,

  [MessageModes.GameBigTop] = SpeakTypesSettings.none, -- ignored
  [MessageModes.GameBigCenter] = SpeakTypesSettings.none, -- ignored
  [MessageModes.GameBigBottom] = SpeakTypesSettings.none, -- ignored

  [MessageModes.RVRContinue] = SpeakTypesSettings.none, -- ignored
  [MessageModes.RVRChannel] = SpeakTypesSettings.none, -- ignored

  [MessageModes.Red] = SpeakTypesSettings.none, -- ignored
  [MessageModes.Blue] = SpeakTypesSettings.none, -- ignored

  [MessageModes.Potion] = SpeakTypesSettings.none, -- ignored
  [MessageModes.BeyondLast] = SpeakTypesSettings.none, -- ignored
  [MessageModes.Attention] = SpeakTypesSettings.none, -- ignored
  [MessageModes.BoostedCreature] = SpeakTypesSettings.none, -- ignored
  [MessageModes.OfflineTrainning] = SpeakTypesSettings.none, -- ignored
  [MessageModes.Transaction] = SpeakTypesSettings.none, -- ignored
  [MessageModes.ValuableLoot] = SpeakTypesSettings.none, -- ignored
}

SayModes = {
  [1] = { speakTypeDesc = 'whisper', icon = '/images/ui/console/whisper' },
  [2] = { speakTypeDesc = 'say', icon = '/images/ui/console/say' },
  [3] = { speakTypeDesc = 'yell', icon = '/images/ui/console/yell' }
}

ChannelEventFormats = {
  [ChannelEvent.Join]    = loc'${GameConsoleChannelEventJoin}',
  [ChannelEvent.Leave]   = loc'${GameConsoleChannelEventLeave}',
  [ChannelEvent.Invite]  = loc'${GameConsoleChannelEventInvite}',
  [ChannelEvent.Exclude] = loc'${GameConsoleChannelEventExclude}',
}

CHANNEL_ID_LOOT = 2

isChatEnabled = true
consolePanel = nil
headerPanel = nil
contentPanel = nil
footerPanel = nil
consoleContentPanel = nil
consoleTabBar = nil
consoleTextEdit = nil
consoleTextEditInfoButton = nil
channels = nil
channelsWindow = nil
communicationWindow = nil
ownPrivateName = nil
currentMessageIndex = 0
ignoreNpcMessages = false
defaultTab = nil
serverTab = nil
filters = { }

local communicationSettings = {
  useIgnoreList = true,
  useWhiteList = true,
  privateMessages = false,
  yelling = false,
  allowVIPs = false,
  ignoredPlayers = { },
  whitelistedPlayers = { }
}

local showHighlightedUnderline = true

local consoleLog = { }
local MAX_LOGLINES = 500
local MAX_LINES = 100

cloneContentPanel = nil
cloneTabSeparator = nil
cloneTabTipArea = nil
cloneTabBar = nil
clonedTab = nil
cloneTab = nil
clonedSplitter = nil



function GameConsole.init()
  -- Alias
  GameConsole.m = modules.game_console

  connect(g_game, {
    onTalk                  = GameConsole.onTalk,
    onChannelList           = GameConsole.onChannelList,
    onOpenChannel           = GameConsole.onOpenChannel,
    onOpenPrivateChannel    = GameConsole.onOpenPrivateChannel,
    onOpenOwnPrivateChannel = GameConsole.onOpenOwnPrivateChannel,
    onCloseChannel          = GameConsole.onCloseChannel,
    onGameStart             = GameConsole.online,
    onGameEnd               = GameConsole.offline,
    onChannelEvent          = GameConsole.onChannelEvent,
    onClientOptionChanged   = GameConsole.onClientOptionChanged,
  })

  consolePanel = g_ui.loadUI('console', GameInterface.getBottomPanel())
  headerPanel  = consolePanel:getChildById('headerPanel')
  contentPanel = consolePanel:getChildById('contentPanel')
  footerPanel  = consolePanel:getChildById('footerPanel')

  consoleTextEdit = footerPanel:getChildById('consoleTextEdit')
  consoleTextEditInfoButton = footerPanel:getChildById('consoleTextEditInfoButton')
  consoleTextEditInfoButton:setVisible(GameConsole.isChatEnabled())
  consoleContentPanel = contentPanel:getChildById('consoleContentPanel')
  consoleTabBar = headerPanel:getChildById('consoleTabBar')
  consoleTabBar:setContentWidget(consoleContentPanel)

  cloneContentPanel = contentPanel:getChildById('cloneContentPanel')
  cloneTabSeparator = headerPanel:getChildById('cloneTabSeparator')
  cloneTabTipArea = headerPanel:getChildById('cloneTabTipArea')
  cloneTabBar = headerPanel:getChildById('cloneTabBar')
  cloneTabBar:setContentWidget(cloneContentPanel)
  clonedSplitter = contentPanel:getChildById('clonedSplitter')

  cloneTabTipArea.onDoubleClick = function(mousePosition)
    if clonedTab then -- cloneTabTipArea is not visible
      return
    end
    GameConsole.toggleClonedTab(GameConsole.getCurrentTab())
  end

  channels = { }

  consolePanel.onKeyPress = function(self, keyCode, keyboardModifiers)
    if not (keyboardModifiers == KeyboardCtrlModifier and keyCode == KeyC) then
      return false
    end

    local tab = GameConsole.getCurrentTab()
    if not tab then
      return false
    end

    local consoleBuffer = tab.tabPanel:getChildById('consoleBuffer')
    if not consoleBuffer.selectionText then
      return false
    end

    return UITextMessageSelection.copy(consoleBuffer) ~= ''
  end

  g_keyboard.bindKeyPress('Alt+Up', function()
    GameConsole.navigateConsoleLog(1)
    return true
  end, consolePanel)
  g_keyboard.bindKeyPress('Alt+Down', function()
    GameConsole.navigateConsoleLog(-1)
    return true
  end, consolePanel)
  g_keyboard.bindKeyPress('Tab', function() consoleTabBar:selectNextTab() end, consolePanel)
  g_keyboard.bindKeyPress('Shift+Tab', function() consoleTabBar:selectPrevTab() end, consolePanel)
  g_keyboard.bindKeyDown('Enter', GameConsole.onEnterKeyDown, consolePanel)

  -- apply buttom functions after loaded
  consoleTabBar:setNavigation(headerPanel:getChildById('prevChannelButton'), headerPanel:getChildById('nextChannelButton'))
  consoleTabBar.onTabChange = GameConsole.onTabChange

  consoleToggleChat = footerPanel:getChildById('toggleChat')

  g_keyboard.bindKeyDown('Ctrl+O', g_game.requestChannels)

  if g_game.isOnline() then
    GameConsole.online()
  end
end

function GameConsole.terminate()
  disconnect(g_game, {
    onTalk                  = GameConsole.onTalk,
    onChannelList           = GameConsole.onChannelList,
    onOpenChannel           = GameConsole.onOpenChannel,
    onOpenPrivateChannel    = GameConsole.onOpenPrivateChannel,
    onOpenOwnPrivateChannel = GameConsole.onOpenOwnPrivateChannel,
    onCloseChannel          = GameConsole.onCloseChannel,
    onGameStart             = GameConsole.online,
    onGameEnd               = GameConsole.offline,
    onChannelEvent          = GameConsole.onChannelEvent,
    onClientOptionChanged   = GameConsole.onClientOptionChanged,
  })

  g_keyboard.unbindKeyDown('Ctrl+O')

  GameConsole.saveCommunicationSettings()
  GameConsole.closeClonedTab()

  if channelsWindow then
    channelsWindow:destroy()
  end

  if communicationWindow then
    communicationWindow:destroy()
  end

  consoleTabBar = nil
  consoleContentPanel = nil
  consoleToggleChat = nil
  consoleTextEdit = nil
  consoleTextEditInfoButton = nil

  cloneTabBar = nil
  cloneTabSeparator = nil
  cloneTabTipArea = nil
  cloneContentPanel = nil
  clonedTab = nil
  cloneTab = nil

  consolePanel:destroy()
  consolePanel = nil
  ownPrivateName = nil

  _G.GameConsole = nil
end

function GameConsole.clearSelection(consoleBuffer)
  UITextMessageSelection.clear(consoleBuffer)
end

function GameConsole.selectAll(consoleBuffer)
  UITextMessageSelection.selectAll(consoleBuffer)
end

function GameConsole.onEnableChat()
  local gameWalk = modules.game_walk

  gameWalk.unbindWalkKey('W')
  gameWalk.unbindWalkKey('A')
  gameWalk.unbindWalkKey('S')
  gameWalk.unbindWalkKey('D')

  gameWalk.unbindWalkKey('Q')
  gameWalk.unbindWalkKey('E')
  gameWalk.unbindWalkKey('Z')
  gameWalk.unbindWalkKey('C')

  gameWalk.unbindTurnKey('Ctrl+W')
  gameWalk.unbindTurnKey('Ctrl+A')
  gameWalk.unbindTurnKey('Ctrl+S')
  gameWalk.unbindTurnKey('Ctrl+D')

  g_keyboard.bindKeyDown('Ctrl+W', GameConsole.removeCurrentTab)

  signalcall(g_game.onToggleChat, true)
end

function GameConsole.onDisableChat()
  g_keyboard.unbindKeyDown('Ctrl+W')

  local gameWalk = modules.game_walk

  gameWalk.bindWalkKey('W', North)
  gameWalk.bindWalkKey('A', West)
  gameWalk.bindWalkKey('S', South)
  gameWalk.bindWalkKey('D', East)

  gameWalk.bindWalkKey('Q', NorthWest)
  gameWalk.bindWalkKey('E', NorthEast)
  gameWalk.bindWalkKey('Z', SouthWest)
  gameWalk.bindWalkKey('C', SouthEast)

  gameWalk.bindTurnKey('Ctrl+W', North, true)
  gameWalk.bindTurnKey('Ctrl+A', West, true)
  gameWalk.bindTurnKey('Ctrl+S', South, true)
  gameWalk.bindTurnKey('Ctrl+D', East, true)

  signalcall(g_game.onToggleChat, false)
end

function GameConsole.onClientOptionChanged(key, value, force, wasClientSettingUp)
  if key == "enableChat" then -- chat toggle
    if value and GameConsole.isChatEnabled() then
      GameConsole.enableChat()
    else
      GameConsole.disableChat()
    end
  elseif key == "showChat" then -- panel toggle
    if value and GameConsole.isChatEnabled() then
      GameConsole.enableChat()
    else
      GameConsole.disableChat()
    end
  end
end

function GameConsole.enableChat()
  if isChatEnabled then return end

  isChatEnabled = true

  consoleTextEdit:setVisible(true)
  consoleTextEdit:setText('')
  consoleTextEdit:enable()
  consoleTextEditInfoButton:show()

  consoleToggleChat:setTooltip(loc'${GameConsoleChatDisable}')

  GameConsole.onEnableChat()
end

function GameConsole.disableChat()
  if not isChatEnabled then return end

  isChatEnabled = false

  consoleTextEditInfoButton:hide()
  consoleTextEdit:setVisible(false)
  consoleTextEdit:setText('')
  consoleTextEdit:disable()

  consoleToggleChat:setTooltip(loc'${GameConsoleChatEnable}')

  GameConsole.onDisableChat()
end

function GameConsole.isChatEnabled()
  return ClientOptions.getOption("showChat") and ClientOptions.getOption("enableChat")
end

function GameConsole.load()
  local settings = g_playerSettings.get('log.console')

  -- Load kept console log after login
  consoleLog = settings and settings:getList('consoleLog') or { }

  local consoleSettings = g_settings.getNode('game_console') or { }
  showHighlightedUnderline = consoleSettings.showHighlightedUnderline
  if showHighlightedUnderline == nil then
    showHighlightedUnderline = ClientOptions.getOption('showHighlightedUnderline')
  end
  if showHighlightedUnderline == nil then
    showHighlightedUnderline = true
  end

  GameConsole.loadCommunicationSettings()
end

function GameConsole.save()
  local logSettings = g_playerSettings.get('log.console')

  -- Keep console log after logout
  if logSettings then
    logSettings:setList('consoleLog', consoleLog)
    logSettings:save()
  end

  local consoleSettings = g_settings.getNode('game_console') or { }
  consoleSettings.showHighlightedUnderline = showHighlightedUnderline
  g_settings.setNode('game_console', consoleSettings)

  -- Save last open channels
  local settings = g_playerSettings.get()
  if not settings then
    return
  end

  local lastChannelsOpen = settings:getNode('lastChannelsOpen') or { }
  local savedChannels = { }
  local set = false
  for channelId, channelName in pairs(channels) do
    if type(channelId) == 'number' then
      savedChannels[channelName] = channelId
      set = true
    end
  end
  if set then
    lastChannelsOpen = savedChannels
  else
    lastChannelsOpen = { }
  end
  settings:setNode('lastChannelsOpen', lastChannelsOpen)
  settings:save()
end

function GameConsole.onTabChange(tabBar, tab)
  if tab == defaultTab or tab == serverTab then
    headerPanel:getChildById('closeChannelButton'):disable()
  else
    headerPanel:getChildById('closeChannelButton'):enable()
  end

  GameConsole.updateTyping(consoleTextEdit:getText(), tab)
end

function GameConsole.updateTyping(text, tab)
  local player = g_game.getLocalPlayer()
  if not player then
    return
  end

  tab = tab or GameConsole.getCurrentTab()
  local typing = text ~= '' and (tab == defaultTab or tab == serverTab)
  if player:getTyping() ~= typing then
    player:setTyping(typing)
    player:sendTyping()
  end
end

function GameConsole.onTextChange(text)
  GameConsole.updateTyping(text)
end

function GameConsole.clear()
  -- Close channels
  for _, channelName in pairs(channels) do
    local tab = consoleTabBar:getTab(channelName)
    consoleTabBar:removeTab(tab)
  end
  channels = { }
  ownPrivateName = nil

  consoleTabBar:removeTab(defaultTab)
  defaultTab = nil
  consoleTabBar:removeTab(serverTab)
  serverTab = nil

  local npcTab = consoleTabBar:getTab(NpcChannelName)
  if npcTab then
    consoleTabBar:removeTab(npcTab)
    npcTab = nil
  end

  consoleTextEdit:clearText()

  if channelsWindow then
    channelsWindow:destroy()
    channelsWindow = nil
  end
end

function GameConsole.clearChannel()
  local tab = GameConsole.getCurrentTab()
  if not tab then
    return
  end

  tab.tabPanel:getChildById('consoleBuffer'):destroyChildren()

  if tab == clonedTab then
    cloneTab.tabPanel:getChildById('consoleBuffer'):destroyChildren()
  end
end

function GameConsole.setTextEditText(text)
  consoleTextEdit:setText(text)
  consoleTextEdit:setCursorPos(-1)
end

function GameConsole.addTab(name, focus)
  local tab = GameConsole.getTab(name)
  if tab then -- opened already
    if not focus then
      focus = true
    end
  else
    tab = consoleTabBar:addTab(name, nil, GameConsole.processChannelTabMenu)

    tab.onDoubleClick = function(mousePosition)
      GameConsole.toggleClonedTab(tab)
    end
  end

  if focus then
    consoleTabBar:selectTab(tab)
  end

  return tab
end

function GameConsole.removeTab(tab)
  if not tab then
    return
  end

  if type(tab) == 'string' then
    tab = consoleTabBar:getTab(tab)
  end

  if tab == defaultTab or tab == serverTab then
    return
  end

  if tab == clonedTab then
    GameConsole.closeClonedTab(clonedTab)
  end

  if tab.ownerPrivateChannel or tab:getText() == ownPrivateName then
    ownPrivateName = nil
  end

  if tab.channelId then
    -- notificate the server that we are leaving the channel
    for k in pairs(channels) do
      if k == tab.channelId then
        channels[k] = nil
      end
    end
    g_game.leaveChannel(tab.channelId)
  elseif tab:getText() == NpcChannelName then
    g_game.closeNpcChannel()
  end

  consoleTabBar:removeTab(tab)
end

function GameConsole.removeCurrentTab()
  GameConsole.removeTab(GameConsole.getCurrentTab())
end

function GameConsole.getTab(name)
  return consoleTabBar:getTab(name)
end

function GameConsole.getChannelTab(channelId)
  local channel = channels[channelId]
  if channel then
    return GameConsole.getTab(channel)
  end
  return nil
end

function GameConsole.getCurrentTab()
  return consoleTabBar:getCurrentTab()
end

function GameConsole.addChannel(name, id)
  channels[id] = name
  local tab = GameConsole.addTab(name, focus)
  tab.channelId = id
  return tab
end

function GameConsole.addPrivateChannel(receiver)
  channels[receiver] = receiver
  return GameConsole.addTab(receiver, false)
end

function GameConsole.addPrivateText(text, speaktype, name, isPrivateCommand, creatureName)
  local focus = false
  if speaktype.npcChat then
    name  = NpcChannelName
    focus = true
  end

  local privateTab = GameConsole.getTab(name)
  if privateTab == nil then
    if (ClientOptions.getOption('showPrivateMessagesInConsole') and not focus) or (isPrivateCommand and not privateTab) then
      privateTab = defaultTab
    else
      privateTab = GameConsole.addTab(name, focus)
      channels[name] = name
    end
    if privateTab then
      privateTab.npcChat = speaktype.npcChat
    end
  elseif focus and privateTab then
    consoleTabBar:selectTab(privateTab)
  end
  GameConsole.addTabText(text, speaktype, privateTab, creatureName)
end

function GameConsole.addText(text, speaktype, tabName, creatureName)
  local tab = GameConsole.getTab(tabName)
  if tab ~= nil then
    GameConsole.addTabText(text, speaktype, tab, creatureName)
  end
end

function GameConsole.addServerLog(text)
  if serverTab then
    GameConsole.addTabText(text, SpeakTypesSettings.channelWhite, serverTab)
  end
end

function GameConsole.setShowHighlightedUnderline(value)
  showHighlightedUnderline = value
end

-- Converts NPC highlight markers into interactive text events.
function GameConsole.getHighlightedText(text)
  local eventParts = { }
  local hasHighlights = false
  local sourcePosition = 1

  for startPosition, content, endPosition in text:gmatch('()%{([^}]*)%}()') do
    local prefix = text:sub(sourcePosition, startPosition - 1)
    eventParts[#eventParts + 1] = prefix

    local textPart = content:match('([^,]+)') or content
    local highlighted = textPart:match('^%s*(.-)%s*$')

    if showHighlightedUnderline then
      eventParts[#eventParts + 1] = string.format('[text-event]%s[/text-event]', highlighted)
    else
      eventParts[#eventParts + 1] = string.format('[text-event]%s%s[/text-event]', string.char(1), highlighted)
    end
    hasHighlights = hasHighlights or highlighted ~= ''
    sourcePosition = endPosition
  end

  local suffix = text:sub(sourcePosition)
  eventParts[#eventParts + 1] = suffix

  return table.concat(eventParts), hasHighlights
end

function GameConsole.sendNpcMessage(text)
  local npcTab = consoleTabBar:getTab(NpcChannelName)
  if npcTab then
    GameConsole.sendMessage(text, npcTab)
  end
end

function GameConsole.onConsoleTextClicked(widget, text)
  GameConsole.sendNpcMessage(text)
end

function GameConsole.onConsoleTextHovered(widget, text, hovered)
  if hovered then
    g_mouse.pushCursor('pointer')
  else
    g_mouse.popCursor('pointer')
  end
end

function GameConsole.addTabText(text, speaktype, tab, creatureName, clone)
  if not tab or tab.locked or not text or #text == 0 then
    return
  end

  if tab == clonedTab then
    GameConsole.addTabText(text, speaktype, cloneTab, creatureName, true)
  else
    consoleTabBar:blinkTab(tab)
  end

  local lightHour = g_map.getLightHour()
  local h         = math.floor(lightHour / 60)
  local m         = lightHour % 60

  if ClientOptions.getOption('showTimestampsInConsole') then
    text = f('%.2d:%.2d %s', h, m, text)
  end

  local characterName = g_game.getCharacterName()
  local panel = clone and cloneTabBar:getTabPanel(tab) or consoleTabBar:getTabPanel(tab)
  local consoleBuffer = panel:getChildById('consoleBuffer')
  local label = g_ui.createWidget('ConsoleLabel', consoleBuffer)
  label:setId('consoleLabel' .. consoleBuffer:getChildCount())
  if speaktype.npcChat and (characterName ~= creatureName or characterName == 'Account Manager') then
    local eventText = GameConsole.getHighlightedText(text)
    label:setTextRich(true)
    label:setColor(speaktype.color)
    label:setEventListener(EVENT_TEXT_HOVER)
    label.interactiveText = eventText
    label:setText(eventText)
    connect(label, {
      onTextHoverChange = GameConsole.onConsoleTextHovered
    })
  elseif speaktype.colored then
    label:setColoredText(text)
    label.coloredData = text
  else
    label:setText(text)
  end
  label:setColor(speaktype.color)

  label.name = creatureName
  consoleBuffer.onMouseRelease = function(self, mousePos, mouseButton)
    GameConsole.processMessageMenu(mousePos, mouseButton, nil, nil, nil, tab)
  end

  label.onMouseRelease = function(self, mousePos, mouseButton)
    if mouseButton == MouseLeftButton then
      local interactiveText = self:getTextByPos(mousePos)
      if interactiveText and interactiveText ~= '' then
        GameConsole.onConsoleTextClicked(self, interactiveText)
        return true
      end
    elseif mouseButton == MouseRightButton then
      GameConsole.processMessageMenu(mousePos, mouseButton, creatureName, text, self, tab)
    end
  end

  UITextMessageSelection.attach(consoleBuffer, label)

  if consoleBuffer:getChildCount() > MAX_LINES then
    local child = consoleBuffer:getFirstChild()
    GameConsole.clearSelection(consoleBuffer)
    child:destroy()
  end
end

function GameConsole.removeTabLabelByName(tab, name)
  local panel = consoleTabBar:getTabPanel(tab)
  local consoleBuffer = panel:getChildById('consoleBuffer')
  for _,label in pairs(consoleBuffer:getChildren()) do
    if label.name == name then
      label:destroy()
    end
  end
end

function GameConsole.openClonedTab(tab)
  if not tab then
    return
  end

  if clonedTab then
    if clonedTab == tab then
      return false
    else -- keep only one open
      GameConsole.closeClonedTab()
    end
  end

  clonedTab = tab
  cloneTab = cloneTabBar:addTab(tab:getText(), nil, GameConsole.processCloneTabMenu)

  cloneTab.onDoubleClick = function()
    GameConsole.closeClonedTab()
  end

  cloneTab:setTooltip(loc'${GameConsoleCloseTabTip}')

  cloneTabSeparator:setOn(true)
  cloneTabTipArea:setOn(true)
  cloneTabBar:setWidth(cloneTab:getWidth()) -- Set tab bar width according to clone tab
  consoleContentPanel:setOn(true)

  clonedSplitter:show()
  clonedSplitter:setMarginRight(g_settings.getNumber('clonedSplitter', contentPanel:getWidth() / 2))
  function clonedSplitter:onDoubleClick(mousePosition)
    self.currentMargin = contentPanel:getWidth() / 2
    self:setMarginRight(self.currentMargin)
  end

  GameConsole.cloneMessages(tab, cloneTab)

  return true
end

function GameConsole.closeClonedTab()
  if not clonedTab or not cloneTab then
    return
  end
  g_settings.set('clonedSplitter', clonedSplitter.currentMargin)

  cloneTabBar:removeTab(cloneTab)

  cloneTabSeparator:setOn(false)
  cloneTabTipArea:setOn(false)
  cloneTabBar:setWidth(0) -- Hide tab bar
  consoleContentPanel:setOn(false)

  clonedSplitter:setMarginRight(0)
  clonedSplitter:hide()
  cloneTab = nil
  clonedTab = nil
end

function GameConsole.toggleClonedTab(tab)
  if not tab then
    return
  end

  if clonedTab == tab then
    GameConsole.closeClonedTab()
  else
    GameConsole.openClonedTab(tab)
  end
end

function GameConsole.cloneMessages(fromTab, toTab)
  local fromBuffer = consoleTabBar:getTabPanel(fromTab):getChildById('consoleBuffer')
  local toBuffer = cloneTabBar:getTabPanel(toTab):getChildById('consoleBuffer')
  for _, label in ipairs(fromBuffer:getChildren()) do
    local cloneLabel = g_ui.createWidget('ConsoleLabel', toBuffer)
    cloneLabel:setId('consoleLabel' .. toBuffer:getChildCount())

    local hasTextClick = label:hasEventListener(EVENT_TEXT_CLICK)
    local hasTextHover = label:hasEventListener(EVENT_TEXT_HOVER)
    if label.interactiveText then
      cloneLabel:setTextRich(true)
      if hasTextHover then
        cloneLabel:setEventListener(EVENT_TEXT_HOVER)
      end
      cloneLabel:setText(label.interactiveText)
    elseif label.coloredData then
      if hasTextClick then
        cloneLabel:setEventListener(EVENT_TEXT_CLICK)
      end
      if hasTextHover then
        cloneLabel:setEventListener(EVENT_TEXT_HOVER)
      end
      cloneLabel:setColoredText(label.coloredData)
    else
      cloneLabel:setText(label:getText())
    end

    cloneLabel:setColor(label:getColor())
    cloneLabel.name = label.name

    if hasTextClick or hasTextHover then
      connect(cloneLabel, {
        onTextClick = hasTextClick and GameConsole.onConsoleTextClicked or nil,
        onTextHoverChange = hasTextHover and GameConsole.onConsoleTextHovered or nil
      })
    end

    cloneLabel.onMouseRelease = label.onMouseRelease
    UITextMessageSelection.attach(toBuffer, cloneLabel)
  end
end

function GameConsole.showOwnChannelPlayerInput(invite)
  local title = invite and loc'${GameConsoleInviteToChat}' or loc'${GameConsoleExcludeFromChat}'
  displayTextInputBox(title, loc'${GameConsoleEnterCharacterName}', function(name)
    name = (name or ''):trim()
    if #name == 0 then
      return
    end

    if invite then
      g_game.inviteToOwnChannel(name)
    else
      g_game.excludeFromOwnChannel(name)
    end
  end)
end

function GameConsole.processChannelTabMenu(tab, mousePos, mouseButton)
  local menu = g_ui.createWidget('PopupMenu')
  menu:setGameMenu(true)

  local channelName = tab:getText()
  local isOwnPrivateTab = tab.ownerPrivateChannel or (ownPrivateName and channelName == ownPrivateName)

  if isOwnPrivateTab then
    menu:addOption(loc'${GameConsoleInviteToChat}', function()
      GameConsole.showOwnChannelPlayerInput(true)
    end)
    menu:addOption(loc'${GameConsoleExcludeFromChat}', function()
      GameConsole.showOwnChannelPlayerInput(false)
    end)
    menu:addSeparator()
  end

  if tab ~= defaultTab and tab ~= serverTab then
    menu:addOption(loc'${CorelibInfoClose}', function() GameConsole.removeTab(channelName) end)
    --menu:addOption(loc'${GameConsoleTabServerMsgs}', function() --[[TODO]] end)
    menu:addSeparator()
  end

  local _tab = GameConsole.getCurrentTab()
  if _tab and _tab == tab then
    menu:addOption(loc'${GameConsoleTabClearMsgs}', function() GameConsole.clearChannel() end)
    menu:addOption(loc'${GameConsoleTabSaveMsgs}', function()
      local panel = consoleTabBar:getTabPanel(tab)
      local consoleBuffer = panel:getChildById('consoleBuffer')
      local lines = { }
      for _,label in pairs(consoleBuffer:getChildren()) do
        table.insert(lines, label:getText())
      end

      local characterName = g_game.getCharacterName()
      local filename = characterName .. ' - ' .. channelName .. '.txt'
      local filepath = '/' .. filename

      -- extra information at the beginning
      table.insert(lines, 1, f(loc'\n${GameConsoleTabSavedAt}', os.date('%a %b %d %H:%M:%S %Y')))

      if g_resources.fileExists(filepath) then
        table.insert(lines, 1, protectedcall(g_resources.readFileContents, filepath) or '')
      end

      g_resources.writeFileContents(filepath, table.concat(lines, '\n'))
      if modules.game_textmessage then
        GameTextMessage.displayStatusMessage(f(loc'${GameConsoleTabAppendedTo}', filename))
      end
    end)

    menu:addSeparator()
    if clonedTab == tab then
      menu:addOption(loc'${GameConsoleTabCloneClose}', function() GameConsole.closeClonedTab() end)
    else
      menu:addOption(loc'${GameConsoleTabClone}', function() GameConsole.openClonedTab(GameConsole.getCurrentTab()) end)
    end
  end

  menu:display(mousePos)
end

function GameConsole.processMessageMenu(mousePos, mouseButton, creatureName, text, label, tab)
  local localPlayer = g_game.getLocalPlayer()
  if mouseButton == MouseRightButton then
    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)
    if creatureName and #creatureName > 0 then
      if creatureName ~= g_game.getCharacterName() then
        menu:addOption(f(loc'${GameConsoleMessageTo}', creatureName), function () g_game.openPrivateChannel(creatureName) end)
        if not localPlayer:hasVip(creatureName) then
          menu:addOption(loc'${GameConsoleAddVIP}', function () g_game.addVip(creatureName) end)
        end
        if GameConsole.getOwnPrivateTab() then
          menu:addSeparator()
          menu:addOption(loc'${GameConsoleInviteToChat}', function() g_game.inviteToOwnChannel(creatureName) end)
          menu:addOption(loc'${GameConsoleExcludeFromChat}', function() g_game.excludeFromOwnChannel(creatureName) end)
        end
        if GameConsole.isIgnored(creatureName) then
          menu:addOption(f(loc'${GameConsoleUnignore}', creatureName), function() GameConsole.removeIgnoredPlayer(creatureName) end)
        else
          menu:addOption(f(loc'${GameConsoleIgnore}', creatureName), function() GameConsole.addIgnoredPlayer(creatureName) end)
        end
        menu:addSeparator()

        if g_game.getAccountType() >= ACCOUNT_TYPE_GAMEMASTER then
          menu:addOption(loc'${GameConsoleAddRuleViolation}', function() if modules.game_ruleviolation then GameRuleViolation.showViewWindow(creatureName, string.utf8Truncate(text, 255)) end end)
        end

        local REPORT_TYPE_STATEMENT = 1
        menu:addOption(loc'${GameConsoleReportStatement}', function() if modules.game_ruleviolation then GameRuleViolation.showRuleViolationReportWindow(REPORT_TYPE_STATEMENT, creatureName, text:match('.+%:%s(.+)')) end end)
        menu:addSeparator()
      end
    end

    local consoleBuffer = tab.tabPanel:getChildById('consoleBuffer')
    local selection = consoleBuffer.selectionText
    if selection and #selection > 0 then
      menu:addOption(loc'${GameConsoleCopy}', function() UITextMessageSelection.copy(consoleBuffer) end, '(Ctrl+C)')
    end
    if text then
      menu:addOption(loc'${GameConsoleCopyMsg}', function() g_window.setClipboardText(text) end)
    end
    if creatureName and #creatureName > 0 then
      menu:addOption(loc'${GameConsoleCopyName}', function () g_window.setClipboardText(creatureName) end)
    end
    menu:addOption(loc'${GameConsoleSelectAll}', function() GameConsole.selectAll(tab.tabPanel:getChildById('consoleBuffer')) end)
    menu:display(mousePos)
  end
end

function GameConsole.processCloneTabMenu(tab, mousePos, mouseButton)
  local menu = g_ui.createWidget('PopupMenu')
  menu:setGameMenu(true)

  menu:addOption(loc'${GameConsoleTabCloneClose}', function() GameConsole.closeClonedTab() end)

  menu:display(mousePos)
end

function GameConsole.onEnterKeyDown()
  local message = consoleTextEdit:getText()

  if #message == 0 then
    ClientOptions.setOption('enableChat', not ClientOptions.getOption('enableChat'))
    return
  end

  if #message > 0 then
    GameConsole.sendMessage(message)

    if ClientOptions.getOption('autoDisableChatOnSendMessage') then
      ClientOptions.setOption('enableChat', false)
    end
  end

  consoleTextEdit:clearText()
end

function GameConsole.addFilter(filter)
  table.insert(filters, filter)
end

function GameConsole.removeFilter(filter)
  table.removevalue(filters, filter)
end

function GameConsole.sendMessage(message, tab)
  local tab = tab or GameConsole.getCurrentTab()
  if not tab then
    return false -- No filter results
  end

  for k,func in pairs(filters) do
    if func(message) then
      return true -- Filter worked
    end
  end

  local localPlayer = g_game.getLocalPlayer()

  -- when talking on server log, the message goes to default channel
  local name = tab:getText()
  if tab == serverTab then
    tab = defaultTab
    name = defaultTab:getText()
  end

  -- handling chat commands
  local channel = tab.channelId
  local originalMessage = message
  local chatCommandSayMode
  local chatCommandPrivate
  local chatCommandPrivateReady
  local chatCommandMessage

  -- player used yell command
  chatCommandMessage = message:match('^%#%w*[y|Y]%w* (.*)')
  if chatCommandMessage ~= nil then
    chatCommandSayMode = 'yell'
    channel = 0
    message = chatCommandMessage
  end

   -- player used whisper
  chatCommandMessage = message:match('^%#%w*[w|W]%w* (.*)')
  if chatCommandMessage ~= nil then
    chatCommandSayMode = 'whisper'
    message = chatCommandMessage
    channel = 0
  end

  -- player say
  chatCommandMessage = message:match('^%#%w*[s|S]%w* (.*)')
  if chatCommandMessage ~= nil then
    chatCommandSayMode = 'say'
    message = chatCommandMessage
    channel = 0
  end

  -- player red talk on channel
  chatCommandMessage = message:match('^%#%w*[c|C]%w* (.*)')
  if chatCommandMessage ~= nil then
    chatCommandSayMode = 'channelRed'
    message = chatCommandMessage
  end

  -- player broadcast
  chatCommandMessage = message:match('^%#%w*[b|B]%w* (.*)')
  if chatCommandMessage ~= nil then
    chatCommandSayMode = 'broadcast'
    message = chatCommandMessage
    channel = 0
  end

  local findIni, findEnd, chatCommandInitial, chatCommandPrivate, chatCommandEnd, chatCommandMessage = message:find('([%*%@])(.+)([%*%@])(.*)')
  if findIni ~= nil and findIni == 1 then -- player used private chat command
    if chatCommandInitial == chatCommandEnd then
      chatCommandPrivateRepeat = false
      if chatCommandInitial == '*' then
        GameConsole.setTextEditText('*'.. chatCommandPrivate .. '* ')
      end
      message = chatCommandMessage:trim()
      chatCommandPrivateReady = true
    end
  end

  message = message:gsub('^(%s*)(.*)', '%2') -- remove space characters from message init
  if #message == 0 then
    return false -- No filter results
  end

  -- Add new command to console log
  currentMessageIndex = 0
  if table.empty(consoleLog) or consoleLog[#consoleLog] ~= originalMessage then -- Empty or last message is different to sent message
    table.insert(consoleLog, originalMessage)
    -- If is full, remove first
    if #consoleLog > MAX_LOGLINES then
      table.remove(consoleLog, 1)
    end
  end

  local speaktypedesc
  if (channel or tab == defaultTab) and not chatCommandPrivateReady then
    if tab == defaultTab then
      speaktypedesc = chatCommandSayMode or SayModes[footerPanel:getChildById('sayModeButton').sayMode].speakTypeDesc
      if speaktypedesc ~= 'say' then -- head back to say mode
        GameConsole.sayModeChange(2)
      end
    else
      speaktypedesc = chatCommandSayMode or 'channelYellow'
    end

    g_game.talkChannel(SpeakTypesSettings[speaktypedesc].speakType, channel, message)

  else
    local isPrivateCommand = false
    local priv = true
    local tabname = name
    if chatCommandPrivateReady then
      speaktypedesc = 'privatePlayerToPlayer'
      name = chatCommandPrivate
      isPrivateCommand = true
    elseif tab.npcChat then
      speaktypedesc = 'privatePlayerToNpc'
    else
      speaktypedesc = 'privatePlayerToPlayer'
    end

    local speaktype = SpeakTypesSettings[speaktypedesc]
    g_game.talkPrivate(speaktype.speakType, name, message)

    message = GameConsole.applyMessagePrefixies(g_game.getCharacterName(), localPlayer:getLevel(), message)
    GameConsole.addPrivateText(message, speaktype, tabname, isPrivateCommand, g_game.getCharacterName())
  end

  return false -- No filter results
end

function GameConsole.sayModeChange(sayMode)
  local button = footerPanel:getChildById('sayModeButton')
  if sayMode == nil then
    sayMode = button.sayMode + 1
  end

  if sayMode > #SayModes then
    sayMode = 1
  end

  button:setIcon(SayModes[sayMode].icon)
  button.sayMode = sayMode
end

function GameConsole.getOwnPrivateTab()
  if not ownPrivateName then
    return
  end

  return GameConsole.getTab(ownPrivateName)
end

function GameConsole.setIgnoreNpcMessages(ignore)
  ignoreNpcMessages = ignore
end

function GameConsole.navigateConsoleLog(step)
  if not GameConsole.isChatEnabled() then
    return
  end

  local numCommands = #consoleLog
  if numCommands > 0 then
    currentMessageIndex = math.min(math.max(currentMessageIndex + step, 0), numCommands)
    if currentMessageIndex > 0 then
      local command = consoleLog[numCommands - currentMessageIndex + 1]
      GameConsole.setTextEditText(command)
    else
      consoleTextEdit:clearText()
    end
  end
end

function GameConsole.applyMessagePrefixies(name, level, message)
  if name and #name > 0 then
    if ClientOptions.getOption('showLevelsInConsole') and level > 0 then
      message = '[' .. level .. '] ' .. name .. ': ' .. message
    else
      message = name .. ': ' .. message
    end
  end
  return message
end

function GameConsole.onTalk(name, level, mode, message, channelId, creaturePos)
  if mode == MessageModes.GamemasterBroadcast then
    if modules.game_textmessage then
      GameTextMessage.displayBroadcastMessage(name .. ': ' .. message)
    end
    return
  end

  local isNpcMode = (mode == MessageModes.NpcFromStartBlock or mode == MessageModes.NpcFrom)

  if ignoreNpcMessages and isNpcMode then
    return
  end

  speaktype = SpeakTypes[mode]

  if not speaktype then
    perror(f(loc'${GameConsoleErrorUnhandledMsgMode}: %s', mode, message))
    return
  end

  local localPlayer = g_game.getLocalPlayer()
  if name ~= g_game.getCharacterName()
      and GameConsole.isUsingIgnoreList()
        and not(GameConsole.isUsingWhiteList()) or (GameConsole.isUsingWhiteList() and not(GameConsole.isWhitelisted(name)) and not(GameConsole.isAllowingVIPs() and localPlayer:hasVip(name))) then

    if mode == MessageModes.Yell and GameConsole.isIgnoringYelling() then
      return
    elseif speaktype.private and GameConsole.isIgnoringPrivate() and not isNpcMode then
      return
    elseif GameConsole.isIgnored(name) then
      return
    end
  end

  if (mode == MessageModes.Say or mode == MessageModes.GamemasterSay or mode == MessageModes.Whisper or mode == MessageModes.Yell or
      mode == MessageModes.Spell or
      mode == MessageModes.NpcFrom or mode == MessageModes.BarkLow or mode == MessageModes.BarkLoud or
      mode == MessageModes.NpcFromStartBlock) and creaturePos
  then
    local staticText = StaticText.create()
    -- Keep interactive NPC text on the gamescreen as well as in the console.
    local staticMessage = message
    if isNpcMode then
      local eventText = GameConsole.getHighlightedText(staticMessage)
      staticText:setTextRich(true)
      staticMessage = eventText
    end

    if speaktype.color then
      staticText:setColor(speaktype.color)
    end
    staticText:addMessage(name, mode, staticMessage)
    g_map.addStaticText(staticText, creaturePos)
  end

  local defaultMessage = mode <= 3 or mode == MessageModes.GamemasterSay

  if speaktype == SpeakTypesSettings.none then
    return
  end

  if speaktype.hideInConsole then
    return
  end

  local composedMessage = GameConsole.applyMessagePrefixies(name, level, message)

  if speaktype.private then
    local tab     = GameConsole.getCurrentTab()
    local tabText = tab:getText()

    GameConsole.addPrivateText(composedMessage, speaktype, name, false, name)

    -- Current tab is not from the player that you received the message
    if tabText ~= name and (not clonedTab or clonedTab:getText() ~= name) and speaktype ~= SpeakTypesSettings.privateNpcToPlayer then
      g_sounds.getChannel(AudioChannels.Gui):play(f('%s/msg_private.ogg', getAudioChannelPath(AudioChannels.Gui)), 1.)

      if ClientOptions.getOption('showPrivateMessagesOnScreen') and modules.game_textmessage then
        GameTextMessage.displayPrivateMessage(f('%s:\n%s', name, message))
      end
    end

  else
    local channel = channels[channelId]
    if not channel and (defaultMessage or channelId == 0) then
      channel = loc'${CorelibInfoDefault}'
    end

    -- If Loot tab is closed, send loot messages to Server tab
    if not channel and channelId == CHANNEL_ID_LOOT then
      channel = serverTab:getText()
    end

    if channel then
      GameConsole.addText(composedMessage, speaktype, channel, name)
    else
      -- server sent a message on a channel that is not open
      pwarning(f(loc'${GameConsoleUnknownMsg}', channelId))
    end
  end
end

function GameConsole.onOpenChannel(channelId, channelName)
  GameConsole.addChannel(channelName, channelId)
end

function GameConsole.onOpenPrivateChannel(receiver)
  GameConsole.addPrivateChannel(receiver)
end

function GameConsole.onOpenOwnPrivateChannel(channelId, channelName)
  local privateTab = GameConsole.getTab(channelName)
  if privateTab == nil then
    privateTab = GameConsole.addChannel(channelName, channelId)
  else
    privateTab.channelId = channelId
  end
  privateTab.ownerPrivateChannel = true
  ownPrivateName = channelName
end

function GameConsole.onCloseChannel(channelId)
  local channel = channels[channelId]
  if channel then
    local tab = GameConsole.getTab(channel)
    if tab then
      if tab.ownerPrivateChannel or tab:getText() == ownPrivateName then
        ownPrivateName = nil
      end
      consoleTabBar:removeTab(tab)
      for k, _ in pairs(channels) do
        if (k == tab.channelId) then
          channels[k] = nil
        end
      end
    end
  end
end

function GameConsole.doChannelListSubmit()
  local channelListPanel = channelsWindow:getChildById('channelList')
  local openPrivateChannelWith = channelsWindow:getChildById('openPrivateChannelWith'):getText()
  if openPrivateChannelWith ~= '' then
    if openPrivateChannelWith:lower() ~= g_game.getCharacterName():lower() then
      g_game.openPrivateChannel(openPrivateChannelWith)
    else
      if modules.game_textmessage then
        GameTextMessage.displayFailureMessage(loc'${GameConsoleChatWithYourself}')
      end
    end
  else
    local selectedChannelLabel = channelListPanel:getFocusedChild()
    if not selectedChannelLabel then
      return
    end

    if selectedChannelLabel.channelId == 0xFFFF then
      g_game.openOwnChannel()
    else
      g_game.joinChannel(selectedChannelLabel.channelId)
    end
  end

  channelsWindow:destroy()
end

function GameConsole.onChannelList(channelList)
  if channelsWindow then
    channelsWindow:destroy()
  end

  channelsWindow = g_ui.displayUI('channelswindow')
  local channelListPanel = channelsWindow:getChildById('channelList')
  channelsWindow.onEnter = GameConsole.doChannelListSubmit
  channelsWindow.onDestroy = function() channelsWindow = nil end
  g_keyboard.bindKeyPress('Down', function() channelListPanel:focusNextChild(KeyboardFocusReason) end, channelsWindow)
  g_keyboard.bindKeyPress('Up', function() channelListPanel:focusPreviousChild(KeyboardFocusReason) end, channelsWindow)

  for k,v in pairs(channelList) do
    local channelId = v[1]
    local channelName = v[2]

    if #channelName > 0 then
      local label = g_ui.createWidget('ChannelListLabel', channelListPanel)
      label.channelId = channelId
      label:setText(channelName)

      label:setPhantom(false)
      label.onDoubleClick = GameConsole.doChannelListSubmit
    end
  end
end

function GameConsole.loadCommunicationSettings()
  communicationSettings.whitelistedPlayers = { }
  communicationSettings.ignoredPlayers = { }

  local ignoreNode = g_settings.getNode('IgnorePlayers')
  if ignoreNode then
    for _, player in pairs(ignoreNode) do
      table.insert(communicationSettings.ignoredPlayers, player)
    end
  end

  local whitelistNode = g_settings.getNode('WhitelistedPlayers')
  if whitelistNode then
    for _, player in pairs(whitelistNode) do
      table.insert(communicationSettings.whitelistedPlayers, player)
    end
  end

  communicationSettings.useIgnoreList = g_settings.getBoolean('UseIgnoreList')
  communicationSettings.useWhiteList = g_settings.getBoolean('UseWhiteList')
  communicationSettings.privateMessages = g_settings.getBoolean('IgnorePrivateMessages')
  communicationSettings.yelling = g_settings.getBoolean('IgnoreYelling')
  communicationSettings.allowVIPs = g_settings.getBoolean('AllowVIPs')
end

function GameConsole.saveCommunicationSettings()
  local tmpIgnoreList = { }
  local ignoredPlayers = GameConsole.getIgnoredPlayers()
  for i = 1, #ignoredPlayers do
    table.insert(tmpIgnoreList, ignoredPlayers[i])
  end

  local tmpWhiteList = { }
  local whitelistedPlayers = GameConsole.getWhitelistedPlayers()
  for i = 1, #whitelistedPlayers do
    table.insert(tmpWhiteList, whitelistedPlayers[i])
  end

  g_settings.set('UseIgnoreList', communicationSettings.useIgnoreList)
  g_settings.set('UseWhiteList', communicationSettings.useWhiteList)
  g_settings.set('IgnorePrivateMessages', communicationSettings.privateMessages)
  g_settings.set('IgnoreYelling', communicationSettings.yelling)
  g_settings.setNode('IgnorePlayers', tmpIgnoreList)
  g_settings.setNode('WhitelistedPlayers', tmpWhiteList)
end

function GameConsole.getIgnoredPlayers()
  return communicationSettings.ignoredPlayers
end

function GameConsole.getWhitelistedPlayers()
  return communicationSettings.whitelistedPlayers
end

function GameConsole.isUsingIgnoreList()
  return communicationSettings.useIgnoreList
end

function GameConsole.isUsingWhiteList()
  return communicationSettings.useWhiteList
end

function GameConsole.isIgnored(name)
  return table.find(communicationSettings.ignoredPlayers, name, true)
end

function GameConsole.addIgnoredPlayer(name)
  if GameConsole.isIgnored(name) then
    return
  end

  table.insert(communicationSettings.ignoredPlayers, name)
end

function GameConsole.removeIgnoredPlayer(name)
  table.removevalue(communicationSettings.ignoredPlayers, name)
end

function GameConsole.isWhitelisted(name)
  return table.find(communicationSettings.whitelistedPlayers, name, true)
end

function GameConsole.addWhitelistedPlayer(name)
  if GameConsole.isWhitelisted(name) then
    return
  end

  table.insert(communicationSettings.whitelistedPlayers, name)
end

function GameConsole.removeWhitelistedPlayer(name)
  table.removevalue(communicationSettings.whitelistedPlayers, name)
end

function GameConsole.isIgnoringPrivate()
  return communicationSettings.privateMessages
end

function GameConsole.isIgnoringYelling()
  return communicationSettings.yelling
end

function GameConsole.isAllowingVIPs()
  return communicationSettings.allowVIPs
end

function GameConsole.onClickIgnoreButton()
  if communicationWindow then
    return
  end

  communicationWindow = g_ui.displayUI('communicationwindow')
  local ignoreListPanel = communicationWindow:getChildById('ignoreList')
  local whiteListPanel = communicationWindow:getChildById('whiteList')
  communicationWindow.onDestroy = function() communicationWindow = nil end

  local useIgnoreListBox = communicationWindow:getChildById('checkboxUseIgnoreList')
  useIgnoreListBox:setChecked(communicationSettings.useIgnoreList)
  local useWhiteListBox = communicationWindow:getChildById('checkboxUseWhiteList')
  useWhiteListBox:setChecked(communicationSettings.useWhiteList)

  local removeIgnoreButton = communicationWindow:getChildById('buttonIgnoreRemove')
  removeIgnoreButton:disable()
  ignoreListPanel.onChildFocusChange = function() removeIgnoreButton:enable() end
  removeIgnoreButton.onClick = function()
    local selection = ignoreListPanel:getFocusedChild()
    if selection then
      ignoreListPanel:removeChild(selection)
      selection:destroy()
    end
    removeIgnoreButton:disable()
  end

  local removeWhitelistButton = communicationWindow:getChildById('buttonWhitelistRemove')
  removeWhitelistButton:disable()
  whiteListPanel.onChildFocusChange = function() removeWhitelistButton:enable() end
  removeWhitelistButton.onClick = function()
    local selection = whiteListPanel:getFocusedChild()
    if selection then
      whiteListPanel:removeChild(selection)
      selection:destroy()
    end
    removeWhitelistButton:disable()
  end

  local newlyIgnoredPlayers = { }
  local addIgnoreName = communicationWindow:getChildById('ignoreNameEdit')
  local addIgnoreButton = communicationWindow:getChildById('buttonIgnoreAdd')
  local addIgnoreFunction = function()
      local newEntry = addIgnoreName:getText()
      if newEntry == '' then
        return
      end

      if table.find(GameConsole.getIgnoredPlayers(), newEntry) then
        return
      end

      if table.find(newlyIgnoredPlayers, newEntry) then
        return
      end

      local label = g_ui.createWidget('IgnoreListLabel', ignoreListPanel)
      label:setText(newEntry)
      table.insert(newlyIgnoredPlayers, newEntry)
      addIgnoreName:setText('')
    end
  addIgnoreButton.onClick = addIgnoreFunction

  local newlyWhitelistedPlayers = { }
  local addWhitelistName = communicationWindow:getChildById('whitelistNameEdit')
  local addWhitelistButton = communicationWindow:getChildById('buttonWhitelistAdd')
  local addWhitelistFunction = function()
      local newEntry = addWhitelistName:getText()
      if newEntry == '' then
        return
      end

      if table.find(GameConsole.getWhitelistedPlayers(), newEntry) then
        return
      end

      if table.find(newlyWhitelistedPlayers, newEntry) then
        return
      end

      local label = g_ui.createWidget('WhiteListLabel', whiteListPanel)
      label:setText(newEntry)
      table.insert(newlyWhitelistedPlayers, newEntry)
      addWhitelistName:setText('')
    end
  addWhitelistButton.onClick = addWhitelistFunction

  communicationWindow.onEnter = function()
      if addWhitelistName:isFocused() then
        addWhitelistFunction()
      elseif addIgnoreName:isFocused() then
        addIgnoreFunction()
      end
    end

  local ignorePrivateMessageBox = communicationWindow:getChildById('checkboxIgnorePrivateMessages')
  ignorePrivateMessageBox:setChecked(communicationSettings.privateMessages)
  local ignoreYellingBox = communicationWindow:getChildById('checkboxIgnoreYelling')
  ignoreYellingBox:setChecked(communicationSettings.yelling)
  local allowVIPsBox = communicationWindow:getChildById('checkboxAllowVIPs')
  allowVIPsBox:setChecked(communicationSettings.allowVIPs)

  local saveButton = communicationWindow:recursiveGetChildById('buttonSave')
  saveButton.onClick = function()
      communicationSettings.ignoredPlayers = { }
      for i = 1, ignoreListPanel:getChildCount() do
        GameConsole.addIgnoredPlayer(ignoreListPanel:getChildByIndex(i):getText())
      end

      communicationSettings.whitelistedPlayers = { }
      for i = 1, whiteListPanel:getChildCount() do
        GameConsole.addWhitelistedPlayer(whiteListPanel:getChildByIndex(i):getText())
      end

      communicationSettings.useIgnoreList = useIgnoreListBox:isChecked()
      communicationSettings.useWhiteList = useWhiteListBox:isChecked()
      communicationSettings.yelling = ignoreYellingBox:isChecked()
      communicationSettings.privateMessages = ignorePrivateMessageBox:isChecked()
      communicationSettings.allowVIPs = allowVIPsBox:isChecked()
      communicationWindow:destroy()
    end

  local cancelButton = communicationWindow:recursiveGetChildById('buttonCancel')
  cancelButton.onClick = function()
      communicationWindow:destroy()
    end

  local ignoredPlayers = GameConsole.getIgnoredPlayers()
  for i = 1, #ignoredPlayers do
    local label = g_ui.createWidget('IgnoreListLabel', ignoreListPanel)
    label:setText(ignoredPlayers[i])
  end

  local whitelistedPlayers = GameConsole.getWhitelistedPlayers()
  for i = 1, #whitelistedPlayers do
    local label = g_ui.createWidget('WhiteListLabel', whiteListPanel)
    label:setText(whitelistedPlayers[i])
  end
end

function GameConsole.online()
  defaultTab = GameConsole.addTab(loc'${CorelibInfoDefault}', true)
  serverTab = GameConsole.addTab(loc'${GameConsoleTabNameServer}', false) -- Server Log

  -- Open last channels
  local settings = g_playerSettings.get()
  for _, channelId in pairs(settings and settings:getNode('lastChannelsOpen') or { }) do
    channelId = tonumber(channelId)
    if channelId ~= -1 and not table.find(channels, channelId) then
      g_game.joinChannel(channelId)
    end
  end

  GameConsole.load()
end

function GameConsole.offline()
  GameConsole.closeClonedTab()
  GameConsole.save()
  GameConsole.clear()
end

function GameConsole.onChannelEvent(channelId, name, type)
  local fmt = ChannelEventFormats[type]
  if not fmt then
    print(f(loc'${GameConsoleUnknownChatEventType}', type))
    return
  end

  local channel = channels[channelId]
  if channel then
    local tab = GameConsole.getTab(channel)
    if tab then
      GameConsole.addTabText(f(fmt, name), SpeakTypesSettings.channelOrange, tab)
    end
  end
end

function GameConsole.getConsolePanel()
  return consolePanel
end

function GameConsole.getHeaderPanel()
  return headerPanel
end

function GameConsole.getContentPanel()
  return contentPanel
end

function GameConsole.getFooterPanel()
  return footerPanel
end

function GameConsole.greetNpc(npc)
  if not g_game.canPerformGameAction() then
    return
  end

  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeGreetNpc)

  msg:addU32(npc:getId())

  protocolGame:send(msg)
end
