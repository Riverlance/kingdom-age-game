g_locales.loadLocales(resolvepath(''))

_G.ClientOptions = { }



ClientOptionsActionKey           = 'Ctrl+Alt+O'
ClientOptionsAudioActionKey      = 'Ctrl+Alt+A'
ClientOptionsFullscreenActionKey = 'Ctrl+Shift+F'

local defaultOptions = {
  optimizeFps = true,
  vsync = true,
  showFps = true,
  showPing = true,
  fullscreen = false,
  classicControl = false,
  autoChaseOverride = true,
  moveFullStack = false,
  showStatusMessagesInConsole = true,
  showEventMessagesInConsole = true,
  showInfoMessagesInConsole = true,
  autoDisableChatOnSendMessage = true,
  showTimestampsInConsole = true,
  showLevelsInConsole = true,
  showPrivateMessagesInConsole = true,
  showPrivateMessagesOnScreen = true,
  enabledLeftPanels = 1,
  enabledRightPanels = 1,
  panelsPriority = 0,
  showLeftPanel = true,
  showRightPanel = true,
  leftFirstPanelWidth = 5,
  rightFirstPanelWidth = 5,
  leftSecondPanelWidth = 5,
  rightSecondPanelWidth = 5,
  leftThirdPanelWidth = 5,
  rightThirdPanelWidth = 5,
  showTopMenu = true,
  showChat = true,
  gameScreenSize = 19,
  backgroundFrameRate = 201,
  enableAudio = true,
  enableMusic = true,
  enableSoundAmbient = true,
  enableSoundEffect = true,
  enableSoundVoice = true,
  enableSoundGui = true,
  musicVolume = 30,
  soundAmbientVolume = 30,
  soundEffectVolume = 70,
  soundVoiceVolume = 100,
  soundGuiVolume = 100,
  showNames = true,
  showLevel = true,
  showIcons = true,
  showHealth = true,
  showMana = true,
  showVigor = true,
  showExpBar = true,
  showText = true,
  showHotkeybars = true,
  clearLootbarItemsOnEachDrop = true,
  enableHighlightMouseTarget = true,
  crosshair = 'default',
  floorViewMode = 1,
  floorFadingDelay = 150,
  shadowFloorIntensity = 50,
  showMouseItemIcon = true,
  mouseItemIconOpacity = 50,
  dontStretchShrink = false,
  shaderFilter = 1,
  showClouds = true,
  viewMode = 3,
  leftSticker = 1,
  rightSticker = 1,
  leftStickerOpacityScrollbar = 50,
  rightStickerOpacityScrollbar = 50,
  smartWalk = false,
  bouncingKeys = true,
  cycleWalk = true,
  cycleWalkDelay = 100,
  bouncingKeysDelayScrollBar = 1000,
  turnDelay = 50,
  hotkeyDelay = 70,
  showMinimapExtraIcons = true,
  goldLootAutoDeposit = true,
  creatureInformationScale = 0,
  staticTextScale = 0,
  animatedTextScale = 0,
}

local optionsWindow
local optionsButton
local optionsTabBar
local options = { }

local gamePanel
local controlPanel
local audioPanel
local graphicPanel
local displayPanel
local panelOptionsPanel
local consolePanel
local audioButton

local leftStickerComboBox
local rightStickerComboBox
local shaderFilterComboBox
local viewModeComboBox
local crosshairComboBox
local floorViewModeComboBox

local sidePanelsRadioGroup



local function setupSidePanelsPriority()
  local priorityLeftSide  = panelOptionsPanel:getChildById('panelsPriorityLeftSide')
  local priorityRightSide = panelOptionsPanel:getChildById('panelsPriorityRightSide')

  sidePanelsRadioGroup = UIRadioGroup.create()
  sidePanelsRadioGroup:addWidget(priorityLeftSide)
  sidePanelsRadioGroup:addWidget(priorityRightSide)

  sidePanelsRadioGroup.onSelectionChange = function(self, selected)
    if selected == priorityLeftSide then
      ClientOptions.setOption('panelsPriority', -1)
    elseif selected == priorityRightSide then
      ClientOptions.setOption('panelsPriority', 1)
    end
  end

  sidePanelsRadioGroup.update = function()
    local hasEnabledLeftPanels  = ClientOptions.getOption('enabledLeftPanels') > 0
    local hasEnabledRightPanels = ClientOptions.getOption('enabledRightPanels') > 0

    priorityLeftSide:setEnabled(hasEnabledLeftPanels)
    priorityRightSide:setEnabled(hasEnabledRightPanels)

    if not hasEnabledLeftPanels and not hasEnabledRightPanels then
      sidePanelsRadioGroup:clearSelected()
      ClientOptions.setOption('panelsPriority', 0)
    else
      local oldPanelsPriority = ClientOptions.getOption('panelsPriority')

      -- Priority order

      -- Has enabled right panels and (not chosen or chosen as right) or right is unique available
      if hasEnabledRightPanels and oldPanelsPriority > -1 or sidePanelsRadioGroup:isUniqueAvailableWidget(priorityRightSide) then
        sidePanelsRadioGroup:selectWidget(priorityRightSide)

      -- Has enabled left panels and (not chosen or chosen as left) or left is unique available
      elseif hasEnabledLeftPanels and oldPanelsPriority < 1 or sidePanelsRadioGroup:isUniqueAvailableWidget(priorityLeftSide) then
        sidePanelsRadioGroup:selectWidget(priorityLeftSide)
      end
    end
  end
end

local clientSettingUp = true
function ClientOptions.setup()
  local mapPanel = GameInterface.getMapPanel()
  -- Disable not needed features of Mehah's client
  g_map.setFloatingEffect(false)
  g_app.setDrawEffectOnTop(false)
  g_app.forceEffectOptimization(false)
  if not g_app.isEncrypted() then -- Async texture load does not work with encryption enabled
    g_app.setLoadingAsyncTexture(false) -- Async texture load makes them load asynchronously and uses less RAM
  end
  mapPanel:setLimitVisibleDimension(false)

  for k,v in pairs(defaultOptions) do
    if type(v) == 'boolean' then
      ClientOptions.setOption(k, g_settings.getBoolean(k), true)
    elseif type(v) == 'number' then
      ClientOptions.setOption(k, g_settings.getNumber(k), true)
    elseif type(v) == 'string' then
      ClientOptions.setOption(k, g_settings.getString(k), true)
    end
  end

  clientSettingUp = false
end



function ClientOptions.init()
  -- Alias
  ClientOptions.m = modules.client_options

  for k,v in pairs(defaultOptions) do
    g_settings.setDefault(k, v)
    options[k] = v
  end

  optionsWindow = g_ui.displayUI('options')
  optionsWindow:hide()

  optionsTabBar = optionsWindow:getChildById('optionsTabBar')
  optionsTabBar:setContentWidget(optionsWindow:getChildById('optionsTabContent'))

  gamePanel         = g_ui.loadUI('game')
  controlPanel      = g_ui.loadUI('control')
  audioPanel        = g_ui.loadUI('audio')
  graphicPanel      = g_ui.loadUI('graphic')
  displayPanel      = g_ui.loadUI('display')
  panelOptionsPanel = g_ui.loadUI('panel')
  consolePanel      = g_ui.loadUI('console')

  setupSidePanelsPriority()

  optionsTabBar:addTab(loc'${ClientOptionsTabTitleGame}', gamePanel, '/images/ui/options/game')
  optionsTabBar:addTab(loc'${ClientOptionsTabTitleControl}', controlPanel, '/images/ui/options/control')
  optionsTabBar:addTab(loc'${ClientOptionsTabTitleAudio}', audioPanel, '/images/ui/options/audio')
  optionsTabBar:addTab(loc'${ClientOptionsTabTitleGraphic}', graphicPanel, '/images/ui/options/graphic')
  optionsTabBar:addTab(loc'${ClientOptionsTabTitleDisplay}', displayPanel, '/images/ui/options/display')
  optionsTabBar:addTab(loc'${ClientOptionsTabTitlePanel}', panelOptionsPanel, '/images/ui/options/panel')
  optionsTabBar:addTab(loc'${ClientOptionsTabTitleConsole}', consolePanel, '/images/ui/options/console')

  g_keyboard.bindKeyDown(ClientOptionsFullscreenActionKey, function() ClientOptions.toggleOption('fullscreen') end)

  optionsButton = ClientTopMenu.addLeftButton('optionsButton', { loct = '${ClientOptionsTitle} (${ClientOptionsActionKey})', locpar = { ClientOptionsActionKey = ClientOptionsActionKey } }, '/images/ui/top_menu/options', ClientOptions.toggle)
  g_keyboard.bindKeyDown(ClientOptionsActionKey, ClientOptions.toggle)
  audioButton = ClientTopMenu.addLeftButton('audioButton', { loct = '${ClientOptionsAudioTitle} (${ClientOptionsAudioActionKey})', locpar = { ClientOptionsAudioActionKey = ClientOptionsAudioActionKey } }, '/images/ui/top_menu/audio', function() ClientOptions.toggleOption('enableAudio') end)
  g_keyboard.bindKeyDown(ClientOptionsAudioActionKey, function() ClientOptions.toggleOption('enableAudio') end)

  -- Mouse item icon example

  local showMouseItemIcon = graphicPanel:getChildById('showMouseItemIcon')
  showMouseItemIcon.onHoverChange = function (self, hovered)
    if hovered then
      g_mouseicon.display(3585, ClientOptions.getOption('mouseItemIconOpacity') / 100, nil, 7)
    else
      g_mouseicon.hide()
    end
  end
  local mouseItemIconOpacity = graphicPanel:getChildById('mouseItemIconOpacity')
  mouseItemIconOpacity.onHoverChange = showMouseItemIcon.onHoverChange

  -- Map shaders

  shaderFilterComboBox = graphicPanel:getChildById('shaderFilter')
  if shaderFilterComboBox then
    for k, shader in ipairs(MapShaders) do
      shaderFilterComboBox:addOption(shader.name, k)
    end
  end

  -- View mode combobox

  viewModeComboBox = graphicPanel:getChildById('viewMode')
  if viewModeComboBox then
    for k = 0, #ViewModes do
      viewModeComboBox:addOption(ViewModes[k].name, k)
    end
  end

  -- Sticker combobox

  leftStickerComboBox = panelOptionsPanel:getChildById('leftSticker')
  rightStickerComboBox = panelOptionsPanel:getChildById('rightSticker')
  if leftStickerComboBox and rightStickerComboBox then
    for k, sticker in ipairs(PanelStickers) do
      leftStickerComboBox:addOption(sticker.opt, k)
      rightStickerComboBox:addOption(sticker.opt, k)
    end
    addEvent(ClientOptions.updateStickers, 500)
  end

  -- Crosshair

  crosshairCombobox = displayPanel:getChildById('crosshair')

  crosshairCombobox:addOption(loc'${ClientOptionsCrosshairValueDisabled}', 'disabled')
  crosshairCombobox:addOption(loc'${CorelibInfoDefault}', 'default')
  crosshairCombobox:addOption(loc'${ClientOptionsCrosshairValueFull}', 'full')

  -- Floor view mode

  floorViewModeComboBox = displayPanel:getChildById('floorViewMode')

  floorViewModeComboBox:addOption(loc'${CorelibInfoDefault}', 0)
  floorViewModeComboBox:addOption(loc'${ClientOptionsFloorViewModeValueFading}', 1)
  floorViewModeComboBox:addOption(loc'${ClientOptionsFloorViewModeValueLocked}', 2)
  floorViewModeComboBox:addOption(loc'${ClientOptionsFloorViewModeValueAlwaysVisible}', 3)
  floorViewModeComboBox:addOption(loc'${ClientOptionsFloorViewModeValueSpy}', 4)

  addEvent(function()
    ClientOptions.setup()



    shaderFilterComboBox.onOptionChange = function(comboBox, option)
      ClientOptions.setOption('shaderFilter', comboBox:getCurrentOption().data)
    end

    viewModeComboBox.onOptionChange = function(comboBox, option)
      ClientOptions.setOption('viewMode', comboBox:getCurrentOption().data)
    end

    leftStickerComboBox.onOptionChange = function(comboBox, option)
      ClientOptions.setOption('leftSticker', comboBox:getCurrentOption().data)
    end
    rightStickerComboBox.onOptionChange = function(comboBox, option)
      ClientOptions.setOption('rightSticker', comboBox:getCurrentOption().data)
    end

    crosshairCombobox.onOptionChange = function(comboBox, option)
      ClientOptions.setOption('crosshair', comboBox:getCurrentOption().data)
    end

    floorViewModeComboBox.onOptionChange = function(comboBox, option)
      ClientOptions.setOption('floorViewMode', comboBox:getCurrentOption().data)
    end
  end)

  connect(g_game, {
    onGameStart = ClientOptions.online,
  })
end

function ClientOptions.terminate()
  disconnect(g_game, {
    onGameStart = ClientOptions.online,
  })

  g_keyboard.unbindKeyDown(ClientOptionsActionKey)
  g_keyboard.unbindKeyDown(ClientOptionsAudioActionKey)
  g_keyboard.unbindKeyDown(ClientOptionsFullscreenActionKey)
  optionsWindow:destroy()
  optionsButton:destroy()
  audioButton:destroy()

  _G.ClientOptions = nil
end

function ClientOptions.toggle()
  if optionsWindow:isVisible() then
    ClientOptions.hide()
  else
    ClientOptions.show()
  end
end

function ClientOptions.show()
  optionsWindow:show()
  optionsWindow:raise()
  optionsWindow:focus()
  optionsButton:setOn(true)
end

function ClientOptions.hide()
  optionsWindow:hide()
  optionsButton:setOn(false)
end

function ClientOptions.toggleOption(key)
  ClientOptions.setOption(key, not ClientOptions.getOption(key))
end

function ClientOptions.updateOption(key) -- Execute functions within its option
  local value = ClientOptions.getOption(key)
  if value == nil then
    return false
  end
  ClientOptions.setOption(key, value, true)
  return true
end

function ClientOptions.setOption(key, value, force)
  if not force and ClientOptions.getOption(key) == value then
    return
  end

  local wasClientSettingUp = clientSettingUp
  local localPlayer        = g_game.getLocalPlayer()

  if key == 'bouncingKeys' then
    controlPanel:getChildById('bouncingKeysDelayScrollBar'):setEnabled(value)

  elseif key == 'cycleWalk' or key == 'cycleWalkDelay' then
    GameInterface.stopCycleWalkEvent()

  elseif key == 'optimizeFps' then
    g_app.optimize(value)

  elseif key == 'vsync' then
    g_window.setVerticalSync(value)

  elseif key == 'showFps' then
    ClientTopMenu.setFpsVisible(value)

  elseif key == 'showPing' then
    ClientTopMenu.setPingVisible(value)

  elseif key == 'fullscreen' then
    g_window.setFullscreen(value)

  elseif key == 'shaderFilter' then
    if g_game.isOnline() then
      ClientShaders.setMapShaderById(value)
    end

  elseif key == 'showClouds' then
    GameInterface.getMapPanel():setCloudsVisible(value)

  elseif key == 'viewMode' then
    if modules.game_interface then
      GameInterface.setupViewMode(g_app.isScaled() and ViewModes[2].id or value)
    end

  elseif key == 'enableAudio' then
    if g_sounds then
      g_sounds.setEnabled(value)
      g_sounds.getChannel(AudioChannels.Music):setEnabled(value and ClientOptions.getOption('enableMusic'))
      g_sounds.getChannel(AudioChannels.Ambient):setEnabled(value and ClientOptions.getOption('enableSoundAmbient'))
      g_sounds.getChannel(AudioChannels.Effect):setEnabled(value and ClientOptions.getOption('enableSoundEffect'))
      g_sounds.getChannel(AudioChannels.Voice):setEnabled(value and ClientOptions.getOption('enableSoundVoice'))
      g_sounds.getChannel(AudioChannels.Gui):setEnabled(value and ClientOptions.getOption('enableSoundGui'))
      if value then
        audioButton:setIcon('/images/ui/top_menu/audio')
        audioButton:setOn(true)
      else
        audioButton:setIcon('/images/ui/top_menu/audio_mute')
        audioButton:setOn(false)
      end
    end

  elseif key == 'enableMusic' then
    if g_sounds then
      g_sounds.getChannel(AudioChannels.Music):setEnabled(ClientOptions.getOption('enableAudio') and value)
    end

  elseif key == 'musicVolume' then
    if g_sounds then
      ClientAudio.setMusicVolume(value / 100)
    end

  elseif key == 'enableSoundAmbient' then
    if g_sounds then
      g_sounds.getChannel(AudioChannels.Ambient):setEnabled(ClientOptions.getOption('enableAudio') and value)
    end

  elseif key == 'soundAmbientVolume' then
    if g_sounds then
      ClientAudio.setAmbientVolume(value / 100)
    end

  elseif key == 'enableSoundEffect' then
    if g_sounds then
      g_sounds.getChannel(AudioChannels.Effect):setEnabled(ClientOptions.getOption('enableAudio') and value)
    end

  elseif key == 'soundEffectVolume' then
    if g_sounds then
      ClientAudio.setEffectVolume(value / 100)
    end

  elseif key == 'enableSoundVoice' then
    if g_sounds then
      g_sounds.getChannel(AudioChannels.Voice):setEnabled(ClientOptions.getOption('enableAudio') and value)
    end

  elseif key == 'soundVoiceVolume' then
    if g_sounds then
      ClientAudio.setVoiceVolume(value / 100)
    end

  elseif key == 'enableSoundGui' then
    if g_sounds then
      g_sounds.getChannel(AudioChannels.Gui):setEnabled(ClientOptions.getOption('enableAudio') and value)
    end

  elseif key == 'soundGuiVolume' then
    if g_sounds then
      ClientAudio.setGuiVolume(value / 100)
    end

  elseif modules.game_interface and key == 'enabledLeftPanels' then
    addEvent(function()
      local hasEnabled = value > 0
      if not wasClientSettingUp then
        sidePanelsRadioGroup.update()
      end

      GameInterface.setLeftPanels()
      if hasEnabled then -- Force left panel to appear
        GameInterface.setLeftPanels()
      end
      GameInterface.moveHiddenPanelMiniWindows()

      GameInterface.m.leftPanelButton:setVisible(hasEnabled)

      panelOptionsPanel:getChildById('leftFirstPanelWidthLabel'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('leftFirstPanelWidth'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('leftSecondPanelWidthLabel'):setEnabled(value >= 2)
      panelOptionsPanel:getChildById('leftSecondPanelWidth'):setEnabled(value >= 2)
      panelOptionsPanel:getChildById('leftThirdPanelWidthLabel'):setEnabled(value >= 3)
      panelOptionsPanel:getChildById('leftThirdPanelWidth'):setEnabled(value >= 3)

      panelOptionsPanel:getChildById('leftStickerLabel'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('leftSticker'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('leftStickerOpacityLabel'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('leftStickerOpacityScrollbar'):setEnabled(value >= 1)
    end)

  elseif modules.game_interface and key == 'enabledRightPanels' then
    addEvent(function()
      local hasEnabled = value > 0
      if not wasClientSettingUp then
        sidePanelsRadioGroup.update()
      end

      GameInterface.setRightPanels()
      if hasEnabled then -- Force right panel to appear
        GameInterface.setRightPanels()
      end
      GameInterface.moveHiddenPanelMiniWindows()

      GameInterface.m.rightPanelButton:setVisible(hasEnabled)

      panelOptionsPanel:getChildById('rightFirstPanelWidthLabel'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('rightFirstPanelWidth'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('rightSecondPanelWidthLabel'):setEnabled(value >= 2)
      panelOptionsPanel:getChildById('rightSecondPanelWidth'):setEnabled(value >= 2)
      panelOptionsPanel:getChildById('rightThirdPanelWidthLabel'):setEnabled(value >= 3)
      panelOptionsPanel:getChildById('rightThirdPanelWidth'):setEnabled(value >= 3)

      panelOptionsPanel:getChildById('rightStickerLabel'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('rightSticker'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('rightStickerOpacityLabel'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('rightStickerOpacityScrollbar'):setEnabled(value >= 1)
    end)

  elseif modules.game_interface and key == 'panelsPriority' then
    addEvent(function()
      if wasClientSettingUp then
        sidePanelsRadioGroup.update()
      end
      GameInterface.setupPanels()
    end)

  elseif modules.game_interface and key == 'showLeftPanel' then
    GameInterface.setLeftPanels(value)

  elseif modules.game_interface and key == 'showRightPanel' then
    GameInterface.setRightPanels(value)

  elseif modules.game_interface and table.contains({ 'leftFirstPanelWidth', 'rightFirstPanelWidth', 'leftSecondPanelWidth', 'rightSecondPanelWidth', 'leftThirdPanelWidth', 'rightThirdPanelWidth' }, key) then
    local width = value * GameSidePanelWidthFactor + GameSidePanelWidthOffset

    if key == 'leftFirstPanelWidth' and GameInterface.m.gameLeftFirstPanel:isVisible() then
      GameInterface.m.gameLeftFirstPanel:setWidth(width)
    elseif key == 'rightFirstPanelWidth' and GameInterface.m.gameRightFirstPanel:isVisible() then
      GameInterface.m.gameRightFirstPanel:setWidth(width)

    elseif key == 'leftSecondPanelWidth' and GameInterface.m.gameLeftSecondPanel:isVisible() then
      GameInterface.m.gameLeftSecondPanel:setWidth(width)
    elseif key == 'rightSecondPanelWidth' and GameInterface.m.gameRightSecondPanel:isVisible() then
      GameInterface.m.gameRightSecondPanel:setWidth(width)

    elseif key == 'leftThirdPanelWidth' and GameInterface.m.gameLeftThirdPanel:isVisible() then
      GameInterface.m.gameLeftThirdPanel:setWidth(width)
    elseif key == 'rightThirdPanelWidth' and GameInterface.m.gameRightThirdPanel:isVisible() then
      GameInterface.m.gameRightThirdPanel:setWidth(width)
    end

  elseif modules.game_interface and key == 'showTopMenu' then
    ClientTopMenu.getTopMenu():setVisible(value)
    GameInterface.getTopMenuButton():setOn(value)

  elseif modules.game_interface and key == 'showChat' then
    GameInterface.getBottomPanel():setVisible(value)
    GameInterface.getSplitter():setVisible(value)
    GameInterface.getChatButton():setOn(value)

    if GameConsole.isChatEnabled() then
      if GameConsole.isChatEnabled(true) then
        GameConsole.onEnableChat()
      end
    else
      GameConsole.onDisableChat()
    end

  elseif modules.game_interface and key == 'gameScreenSize' then
    GameInterface.getMapPanel():setZoom(value)

  elseif key == 'backgroundFrameRate' then
    g_app.setMaxFps(value > 0 and value < 201 and value or 0)

  elseif modules.game_interface and key == 'showNames' then
    GameInterface.getMapPanel():setDrawNames(value)

  elseif modules.game_interface and key == 'showLevel' then
    GameInterface.getMapPanel():setDrawLevels(value)

  elseif modules.game_interface and key == 'showIcons' then
    GameInterface.getMapPanel():setDrawIcons(value)

  elseif modules.game_interface and key == 'showHealth' then
    GameInterface.getMapPanel():setDrawHealthBars(value)

  elseif modules.game_interface and key == 'showMana' then
    GameInterface.updateManaBar(value)

  elseif modules.game_interface and key == 'showVigor' then
    GameInterface.getMapPanel():setDrawVigorBar(value)

  elseif key == 'showExpBar' then
    if not modules.ka_game_ui then
      return
    end
    GameUIExpBar.setExpBar(value)

  elseif modules.game_interface and key == 'showText' then
    g_app.setDrawTexts(value)

  elseif key == 'showHotkeybars' then
    if not modules.ka_game_hotkeybars then
      return
    end
    GameHotkeyBars.onDisplay(value)

  elseif modules.game_interface and key == 'dontStretchShrink' then
    addEvent(function() GameInterface.updateStretchShrink() end)

  elseif modules.game_interface and key == 'leftStickerOpacityScrollbar' then
    local leftStickerWidget = GameInterface.getLeftFirstPanel():getChildById('gameLeftPanelSticker')
    if not leftStickerWidget then
      return
    end

    local _value = math.ceil(value * 2.55)
    local alpha  = f('%s%x', _value < 16 and '0' or '', _value)
    leftStickerWidget:setImageColor(tocolor('#FFFFFF' .. alpha))

  elseif modules.game_interface and key == 'rightStickerOpacityScrollbar' then
    local rightStickerWidget = GameInterface.getRightFirstPanel():getChildById('gameRightPanelSticker')
    if not rightStickerWidget then
      return
    end

    local _value = math.ceil(value * 2.55)
    local alpha  = f('%s%x', _value < 16 and '0' or '', _value)
    rightStickerWidget:setImageColor(tocolor('#FFFFFF' .. alpha))

  elseif key == 'leftSticker' then
    ClientOptions.updateLeftSticker(value)

  elseif key == 'rightSticker' then
    ClientOptions.updateRightSticker(value)

  elseif key == 'enableHighlightMouseTarget' then
    GameInterface.getMapPanel():setDrawHighlightTarget(value)

  elseif key == 'crosshair' then
    local newValue = value
    if newValue == 'disabled' then
      newValue = nil
    end
    GameInterface.getMapPanel():setCrosshairTexture(newValue and '/images/game/crosshair/' .. newValue or nil)

  elseif key == 'floorViewMode' then
    GameInterface.getMapPanel():setFloorViewMode(value)

    local floorFadingDelayWidget = displayPanel:getChildById('floorFadingDelay')
    if floorFadingDelayWidget then
      floorFadingDelayWidget:setEnabled(value == 1)
    end

  elseif key == 'floorFadingDelay' then
    GameInterface.getMapPanel():setFloorFading(tonumber(value) or 150)

  elseif key == 'shadowFloorIntensity' then
    local mapPanel = GameInterface and GameInterface.getMapPanel()
    if mapPanel then
      mapPanel:setShadowFloorIntensity(1 - (value / 100))
    end

  elseif key == 'showMinimapExtraIcons' then
    if not modules.game_minimap then
      return
    end

    local minimapWidget = GameMinimap.getMinimapWidget()
    minimapWidget:setAlternativeWidgetsVisible(value)

    GameMinimap.m.extraIconsButton:setOn(value)

  elseif key == 'goldLootAutoDeposit' then
    if localPlayer then
      g_game.sendGoldLootAutoDepositState(value)
    end

  elseif key == 'creatureInformationScale' then
    g_app.setCreatureInformationScale(math.max((value == 0 and g_window.getDisplayDensity() - 0.5 or value / 2) + 0.5, 1))

  elseif key == 'staticTextScale' then
    g_app.setStaticTextScale(math.max((value == 0 and g_window.getDisplayDensity() - 0.5 or value / 2) + 0.5, 1))

  elseif key == 'animatedTextScale' then
    g_app.setAnimatedTextScale(math.max((value == 0 and g_window.getDisplayDensity() - 0.5 or value / 2) + 0.5, 1))
  end

  -- change value for keybind updates
  for _,panel in pairs(optionsTabBar:getTabsPanel()) do
    local widget = panel:recursiveGetChildById(key)
    if widget then
      if widget:getStyle().__class == 'UICheckBox' then
        widget:setChecked(value)
      elseif widget:getStyle().__class == 'UIScrollBar' then
        widget:setValue(value)
      elseif widget:getStyle().__class == 'UIComboBox' then
        widget:setCurrentOptionByData(value)
      end
      break
    end
  end

  g_settings.set(key, value)
  options[key] = value

  signalcall(g_game.onClientOptionChanged, key, value, force, wasClientSettingUp)
end

function ClientOptions.getOption(key)
  return options[key]
end

function ClientOptions.addTab(name, panel, icon)
  optionsTabBar:addTab(name, panel, icon)
end

function ClientOptions.removeTab(tab)
  if type(tab) == "string" then
    tab = optionsTabBar:getTab(tab)
  end

  optionsTabBar:removeTab(tab)
end

function ClientOptions.addButton(name, func, icon)
  optionsTabBar:addButton(name, func, icon)
end



-- Panel Stickers

function ClientOptions.updateLeftSticker(value)
  local leftStickerWidget = GameInterface.getLeftFirstPanel():getChildById('gameLeftPanelSticker')
  if leftStickerWidget then
    value      = value or g_settings.getNumber('leftSticker')
    local path = PanelStickers[value] and PanelStickers[value].path or ''

    if path ~= '' then
      leftStickerComboBox:setTooltip(path, TooltipType.image)
    else
      leftStickerComboBox:removeTooltip()
    end
    leftStickerWidget:setImageSource(path)
  end
end

function ClientOptions.updateRightSticker(value)
  local rightStickerWidget = GameInterface.getRightFirstPanel():getChildById('gameRightPanelSticker')
  if rightStickerWidget then
    value      = value or g_settings.getNumber('rightSticker')
    local path = PanelStickers[value] and PanelStickers[value].path or ''

    if path ~= '' then
      rightStickerComboBox:setTooltip(path, TooltipType.image)
    else
      rightStickerComboBox:removeTooltip()
    end
    rightStickerWidget:setImageSource(path)
  end
end

function ClientOptions.updateStickers()
  ClientOptions.updateLeftSticker()
  ClientOptions.updateRightSticker()
end



-- Event

function ClientOptions.online()
  -- Gold loot auto deposit
  g_game.sendGoldLootAutoDepositState(ClientOptions.getOption('goldLootAutoDeposit'))
end
