g_locales.loadLocales(resolvepath(''))

_G.GameTextMessage = { }



local DefaultFont = {
  path = 'verdanapro-v',
  weight = 700,
}
local function setMessageFont(widget, font)
  local descriptor = font or DefaultFont
  local path = descriptor.path or DefaultFont.path
  local size = descriptor.size or 11
  local strokeWidth = descriptor.strokeWidth or 0
  local strokeColor = tocolor(descriptor.strokeColor or 'black')

  -- Keep the old bold default while allowing custom message fonts to remain
  -- static unless they explicitly request variable-font properties.
  local weight = descriptor.weight
  if not descriptor.path then
    weight = weight or DefaultFont.weight
  end

  if weight ~= nil or descriptor.width ~= nil or descriptor.italic ~= nil or descriptor.variations ~= nil then
    widget:setTTFFontVariations(
      path,
      size,
      strokeWidth,
      strokeColor,
      weight or -1,
      descriptor.width or -1,
      descriptor.italic == nil and -1 or (descriptor.italic and 1 or 0),
      descriptor.variations or '')
  else
    widget:setTTFFont(path, size, strokeWidth, strokeColor)
  end
end

MessageSettings = {
  none = { },

  channelYellow = { color = TextColors.yellow },
  channelWhite  = { color = TextColors.white },
  channelRed    = { color = TextColors.red },
  channelOrange = { color = TextColors.orange },

  consoleYellow = { color = TextColors.yellow, consoleTab = loc'${CorelibInfoDefault}' },
  consoleRed    = { color = TextColors.red,    consoleTab = loc'${CorelibInfoDefault}' },
  consoleOrange = { color = TextColors.orange, consoleTab = loc'${CorelibInfoDefault}' },
  consoleBlue   = { color = TextColors.blue,   consoleTab = loc'${CorelibInfoDefault}' },

  centerWhite   = { color = TextColors.white, consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'middleCenterLabel', font = { strokeWidth = 1 }, consoleOption = 'showEventMessagesInConsole' },
  centerGreen   = { color = TextColors.green, consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'highCenterLabel', font = { strokeWidth = 1 },   consoleOption = 'showInfoMessagesInConsole' },
  centerHKGreen = { color = TextColors.green, consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'highCenterLabel', font = { strokeWidth = 1 },   consoleOption = 'showInfoMessagesInConsole' },
  centerRed     = { color = TextColors.red,   consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'lowCenterLabel', font = { strokeWidth = 1 } },

  bottomWhite = { color = TextColors.white, consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'statusLabel', font = { strokeWidth = 1 }, consoleOption = 'showEventMessagesInConsole' },

  statusSmall   = { color = TextColors.white,                                                screenTarget = 'statusLabel', font = { strokeWidth = 1 } },
  status        = { color = TextColors.white, consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'statusLabel', font = { strokeWidth = 1 }, consoleOption = 'showStatusMessagesInConsole' },
  statusBoosted = { color = TextColors.white, consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'statusLabel', font = { strokeWidth = 1 }, consoleOption = 'showStatusMessagesInConsole' },
  statusOwn     = { color = TextColors.white, consoleTab = loc'${GameConsoleTabNameServer}',                                                           consoleOption = 'showStatusMessagesInConsole' },
  othersStatus  = { color = TextColors.white, consoleTab = loc'${GameConsoleTabNameServer}',                                                           consoleOption = 'showOthersStatusMessagesInConsole' },

  loot         = { color = TextColors.white, consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'highCenterLabel', font = { strokeWidth = 1 }, consoleOption = 'showInfoMessagesInConsole', colored = true },
  valuableLoot = { color = TextColors.white, consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'statusLabel',     font = { strokeWidth = 1 }, consoleOption = 'showInfoMessagesInConsole', colored = true },

  private               = { color = TextColors.lightblue, consoleTab = loc'${CorelibInfoDefault}', screenTarget = 'privateLabel', font = { strokeWidth = 1 } },
  privateRed            = { color = TextColors.red,       consoleTab = loc'${CorelibInfoDefault}', private = true },
  privatePlayerToPlayer = { color = TextColors.blue, consoleTab = loc'${CorelibInfoDefault}',      private = true },
  privatePlayerToNpc    = { color = TextColors.blue, consoleTab = loc'${CorelibInfoDefault}',      private = true, npcChat = true },
  privateNpcToPlayer    = { color = TextColors.lightblue, consoleTab = loc'${CorelibInfoDefault}', private = true, npcChat = true },

  monsterSay  = { color = TextColors.orange, hideInConsole = true },
  monsterYell = { color = TextColors.orange, hideInConsole = true },

  statusBigTop    = { color = '#e1e1e1', consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'privateLabel', font = { strokeWidth = 1 },      consoleOption = 'showStatusMessagesInConsole', font = { path = 'limited/martel', size = 20, strokeWidth = 2 } },
  statusBigCenter = { color = '#e1e1e1', consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'middleCenterLabel', font = { strokeWidth = 1 }, consoleOption = 'showStatusMessagesInConsole', font = { path = 'limited/martel', size = 20, strokeWidth = 2 } },
  statusBigBottom = { color = '#e1e1e1', consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'statusLabel', font = { strokeWidth = 1 },       consoleOption = 'showStatusMessagesInConsole', font = { path = 'limited/martel', size = 20, strokeWidth = 2 } },

  potion = { color = TextColors.orange, hideInConsole = true },

  look = { color = '#e6db74', consoleTab = loc'${GameConsoleTabNameServer}', consoleOption = 'showInfoMessagesInConsole' },
}

MessageTypes = {
  [MessageModes.Say] = MessageSettings.consoleYellow,
  [MessageModes.Whisper] = MessageSettings.consoleYellow,
  [MessageModes.Yell] = MessageSettings.consoleYellow,

  [MessageModes.PrivateFrom] = MessageSettings.private,
  [MessageModes.PrivateTo] = MessageSettings.privatePlayerToPlayer,

  [MessageModes.ChannelManagement] = MessageSettings.channelWhite,
  [MessageModes.Channel] = MessageSettings.channelYellow,
  [MessageModes.ChannelHighlight] = MessageSettings.channelOrange,

  [MessageModes.Spell] = MessageSettings.consoleYellow,

  [MessageModes.NpcFromStartBlock] = MessageSettings.privateNpcToPlayer,
  [MessageModes.NpcFrom] = MessageSettings.privateNpcToPlayer,
  [MessageModes.NpcTo] = MessageSettings.privatePlayerToNpc,

  [MessageModes.GamemasterBroadcast] = MessageSettings.consoleRed,
  [MessageModes.GamemasterChannel] = MessageSettings.channelRed,
  [MessageModes.GamemasterPrivateFrom] = MessageSettings.privateRed,
  [MessageModes.GamemasterPrivateTo] = MessageSettings.privateRed,

  [MessageModes.Login] = MessageSettings.bottomWhite,
  [MessageModes.Warning] = MessageSettings.centerRed,
  [MessageModes.Game] = MessageSettings.centerWhite,
  [MessageModes.GameHighlight] = MessageSettings.centerRed,
  [MessageModes.Failure] = MessageSettings.statusSmall,
  [MessageModes.Look] = MessageSettings.look,

  [MessageModes.DamageDealed] = MessageSettings.statusOwn,
  [MessageModes.DamageReceived] = MessageSettings.statusOwn,
  [MessageModes.Heal] = MessageSettings.statusOwn,
  [MessageModes.Exp] = MessageSettings.statusOwn,
  [MessageModes.DamageOthers] = MessageSettings.othersStatus,
  [MessageModes.HealOthers] = MessageSettings.othersStatus,
  [MessageModes.ExpOthers] = MessageSettings.othersStatus,

  [MessageModes.Status] = MessageSettings.status,
  [MessageModes.Loot] = MessageSettings.loot, -- centerGreen?
  [MessageModes.TradeNpc] = MessageSettings.centerGreen,
  [MessageModes.Guild] = MessageSettings.statusOwn, -- centerGreen?

  [MessageModes.PartyManagement] = MessageSettings.centerGreen,
  [MessageModes.Party] = MessageSettings.statusOwn, -- centerGreen?

  [MessageModes.BarkLow] = MessageSettings.monsterSay,
  [MessageModes.BarkLoud] = MessageSettings.monsterYell,

  [MessageModes.Report] = MessageSettings.centerWhite,
  [MessageModes.HotkeyUse] = MessageSettings.centerGreen,
  [MessageModes.TutorialHint] = MessageSettings.statusSmall,

  [MessageModes.GameBigTop] = MessageSettings.statusBigTop,
  [MessageModes.GameBigCenter] = MessageSettings.statusBigCenter,
  [MessageModes.GameBigBottom] = MessageSettings.statusBigBottom,

  [MessageModes.RVRContinue] = MessageSettings.consoleYellow,
  [MessageModes.RVRChannel] = MessageSettings.channelWhite,

  [MessageModes.Red] = MessageSettings.consoleRed,
  [MessageModes.Blue] = MessageSettings.consoleBlue,

  [MessageModes.Potion] = MessageSettings.potion,
  [MessageModes.BeyondLast] = MessageSettings.centerWhite,
  [MessageModes.Attention] = MessageSettings.bottomWhite,
  [MessageModes.BoostedCreature] = MessageSettings.centerWhite,
  [MessageModes.OfflineTrainning] = MessageSettings.centerWhite,
  [MessageModes.Transaction] = MessageSettings.centerWhite,
  [MessageModes.ValuableLoot] = MessageSettings.valuableLoot, -- centerGreen?

  [254] = MessageSettings.private
}

messagesPanel = nil
statusLabel = nil

-- Look hover
lookLastConsoleKey  = nil
lookLastConsoleText = nil



function GameTextMessage.init()
  -- Alias
  GameTextMessage.m = modules.game_textmessage

  for messageMode in pairs(MessageTypes) do
    registerMessageMode(messageMode, GameTextMessage.displayMessage)
  end

  connect(g_game, {
    onClientOptionChanged = GameTextMessage.onClientOptionChanged,
    onGameEnd             = GameTextMessage.clearMessages,
  })
  connect(GameInterface.getMapPanel(), {
    onGeometryChange = GameTextMessage.onGeometryChange,
    onViewModeChange = GameTextMessage.onViewModeChange,
    onZoomChange     = GameTextMessage.onZoomChange,
  })

  messagesPanel = g_ui.loadUI('textmessage', GameInterface.getRootPanel())
  statusLabel = messagesPanel:getChildById('statusLabel')
end

function GameTextMessage.terminate()
  for messageMode in pairs(MessageTypes) do
    unregisterMessageMode(messageMode, GameTextMessage.displayMessage)
  end

  disconnect(GameInterface.getMapPanel(), {
    onGeometryChange = GameTextMessage.onGeometryChange,
    onViewModeChange = GameTextMessage.onViewModeChange,
    onZoomChange     = GameTextMessage.onZoomChange,
  })
  disconnect(g_game, {
    onClientOptionChanged = GameTextMessage.onClientOptionChanged,
    onGameEnd             = GameTextMessage.clearMessages,
  })

  GameTextMessage.clearMessages()
  messagesPanel:destroy()
  messagesPanel = nil

  _G.GameTextMessage = nil
end

local function updateStatusLabelPosition(label)
  local margin = GameInterface.m.chatButton:getHeight() + 4

  -- Hotkey bar
  local bottomHotkeyBar = modules.ka_game_hotkeybars and GameHotkeyBars.getHotkeyBars()[AnchorBottom] or nil
  if bottomHotkeyBar and bottomHotkeyBar:isVisible() then
    margin = margin + bottomHotkeyBar:getHeight()
  end

  -- Experience bar
  if GameInterface.m.gameExpBar:isOn() then
    margin = margin + GameInterface.m.gameExpBar:getHeight()
  end

  label:setMarginBottom(margin)
end

function GameTextMessage.onGeometryChange(mapPanel)
  updateStatusLabelPosition(statusLabel)
end

function GameTextMessage.onViewModeChange(mapWidget, viewMode, oldViewMode)
  updateStatusLabelPosition(statusLabel)
end

function GameTextMessage.onClientOptionChanged(key, value, force, wasClientSettingUp)
  updateStatusLabelPosition(statusLabel)
end

function GameTextMessage.onZoomChange(self, oldZoom, newZoom)
  if oldZoom == newZoom then
    return
  end

  addEvent(withWeakWidget(statusLabel, function(widget) updateStatusLabelPosition(widget) end))
end

function GameTextMessage.calculateVisibleTime(text)
  return math.max(#text * 50, 4000)
end

function GameTextMessage.displayMessage(mode, text)
  if not g_game.isOnline() then
    return
  end

  local msgtype = MessageTypes[mode]
  if not msgtype then
    return
  end

  if msgtype == MessageSettings.none then
    return
  end

  local skipConsole = false

  -- Look hover
  if mode == MessageModes.Look then
    GameInterface.handleHoverLookMessage(text)

    -- If the text is the same as the last one, skip the console
    local lookConsoleKey = GameInterface.getHoverLookConsoleKey()
    if lookConsoleKey then
      skipConsole = lookLastConsoleKey == lookConsoleKey and lookLastConsoleText == text

      if not skipConsole then
        lookLastConsoleKey  = lookConsoleKey
        lookLastConsoleText = text
      end
    else
      lookLastConsoleKey  = nil
      lookLastConsoleText = nil
    end
  end

  if not skipConsole and msgtype.consoleTab ~= nil and (msgtype.consoleOption == nil or ClientOptions.getOption(msgtype.consoleOption)) then
    GameConsole.addText(text, msgtype, msgtype.consoleTab)
  end

  if msgtype.screenTarget then
    local label = messagesPanel:recursiveGetChildById(msgtype.screenTarget)
    if msgtype.colored then
      label:setColoredText(text)
    else
      label:setText(text)
    end
    label:setColor(msgtype.color)
    setMessageFont(label, msgtype.font)
    label:setVisible(true)
    if msgtype.screenTarget == 'statusLabel' then
      updateStatusLabelPosition(label)
    end
    removeEvent(label.hideEvent)
    label.hideEvent = scheduleEvent(function()
      if isWidgetAlive(label) then
        label:setVisible(false)
      end
    end, GameTextMessage.calculateVisibleTime(text))
  end
end

function GameTextMessage.displayPrivateMessage(text)
  if not g_game.isOnline() then
    return
  end

  local msgtype = MessageSettings.private
  if not msgtype or not msgtype.screenTarget then
    return
  end

  local label = messagesPanel:recursiveGetChildById(msgtype.screenTarget)
  if not label then
    return
  end

  label:setText(text)
  label:setColor(msgtype.color)
  setMessageFont(label, msgtype.font)
  label:setVisible(true)
  removeEvent(label.hideEvent)
  label.hideEvent = scheduleEvent(function()
    if isWidgetAlive(label) then
      label:setVisible(false)
    end
  end, GameTextMessage.calculateVisibleTime(text))
end

function GameTextMessage.displayStatusMessage(text)
  GameTextMessage.displayMessage(MessageModes.Status, text)
end

function GameTextMessage.displayFailureMessage(text)
  GameTextMessage.displayMessage(MessageModes.Failure, text)
end

function GameTextMessage.displayGameMessage(text)
  GameTextMessage.displayMessage(MessageModes.Game, text)
end

function GameTextMessage.displayBroadcastMessage(text)
  GameTextMessage.displayMessage(MessageModes.Warning, text)
end

function GameTextMessage.clearMessages()
  -- Look hover
  lookLastConsoleKey  = nil
  lookLastConsoleText = nil

  for _i,child in pairs(messagesPanel:recursiveGetChildren()) do
    if child:getId():match('Label') then
      child:hide()
      removeEvent(child.hideEvent)
    end
  end
end



function LocalPlayer:onAutoWalkFail(player)
  if modules.game_textmessage then
    GameTextMessage.displayFailureMessage(loc'${GameTextMessageErrorNoWay}')
  end
end
