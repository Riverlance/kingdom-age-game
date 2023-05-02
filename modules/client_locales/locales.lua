_G.ClientLocales = { }



local debugInfo = false



local currentLocaleId = DefaultLocaleId



localesWindow = nil



function ClientLocales.init()
  -- Alias
  ClientLocales.m = modules.client_locales

  InstalledLocales = { }

  ClientLocales.installLocales()

  local localeId = tonumber(g_settings.get('locale'))
  ClientLocales.setLocale(localeId or DefaultLocaleId)

  if not localeId then
    connect(g_app, {
      onRun = ClientLocales.createWindow
    })
  end

  connect(g_game, {
    onGameStart = ClientLocales.onGameStart
  })
end

function ClientLocales.terminate()
  InstalledLocales = nil

  disconnect(g_game, {
    onGameStart = ClientLocales.onGameStart
  })

  disconnect(g_app, {
    onRun = ClientLocales.createWindow
  })

  _G.ClientLocales = nil
end

function ClientLocales.onGameStart()
  ClientLocales.sendLocale()
end



function ClientLocales.getInstalledLocales()
  return InstalledLocales
end

function ClientLocales.installLocale(locale)
  if not locale or not locale.id then
    error('Unable to install locale.')
  end

  if debugInfo and locale.id ~= DefaultLocaleId then
    local updatesNamesMissing = { }

    for _, msg in pairs(NeededTranslations) do
      if locale.translation[msg] == nil then
        updatesNamesMissing[#updatesNamesMissing + 1] = msg
      end
    end

    if #updatesNamesMissing > 0 then
      pdebug(string.format('Locale \'%d\' is missing %d translations.', locale.id, #updatesNamesMissing))
      for _, name in pairs(updatesNamesMissing) do
        pdebug(string.format('Missing translation:\t"%s"', name))
      end
    end
  end

  local installedLocale = InstalledLocales[locale.id]

  -- If installed already, overwrite translations
  if installedLocale then
    for msg, translation in pairs(locale.translation) do
      installedLocale.translation[msg] = translation
    end
  -- Else, set up
  else
    InstalledLocales[locale.id] = locale
  end
end

function ClientLocales.installLocales()
  dofiles('/locales')
end

function ClientLocales.getLocale()
  return InstalledLocales[currentLocaleId]
end

function ClientLocales.setLocale(id)
  local locale = InstalledLocales[id]

  if not locale then
    error(string.format('Locale %d does not exist.', id))

  elseif locale == ClientLocales.getLocale() then
    g_settings.set('locale', id)
    return
  end

  currentLocaleId = id
  g_settings.set('locale', id)

  ClientLocales.sendLocale()

  if debugInfo then
    pdebug(string.format('Using configured locale: %d', id))
  end
end

function ClientLocales.createWindow()
  localesWindow          = g_ui.displayUI('locales')
  localesWindow.onEscape = ClientLocales.destroyWindow

  local localesPanel = localesWindow:getChildById('localesPanel')
  local layout       = localesPanel:getLayout()
  local spacing      = layout:getCellSpacing()
  local size         = layout:getCellSize()

  local count = 0
  for id, locale in ipairs(InstalledLocales) do
    local widget = g_ui.createWidget('LocalesButton', localesPanel)

    widget:setImageSource(string.format('/images/ui/flags/%s', locale.name))
    widget:setText(locale.languageName)

    widget.onClick = function()
      ClientLocales.destroyWindow()
      ClientLocales.setLocale(id)
      g_modules.reloadModules()
    end

    count = count + 1
  end

  count = math.max(1, math.min(count, 3)) -- Display 3 per line
  localesPanel:setWidth(size.width * count + spacing * (count - 1))

  addEvent(function()
    localesWindow:raise()
    localesWindow:focus()
  end)
end

function ClientLocales.destroyWindow()
  if not localesWindow then
    return
  end

  localesWindow:destroy()
  localesWindow = nil
end



-- Global function used to translate texts
function _G.tr(text, ...)
  local locale = ClientLocales.getLocale()
  if not locale then
    return text
  end

  -- Number
  if tonumber(text) and locale.formatNumbers then
    local number        = tostring(text):split('.')
    local reverseNumber = number[1]:reverse()
    local out           = ''

    for i = 1, #reverseNumber do
      out = out .. reverseNumber:sub(i, i)
      if i % 3 == 0 and i ~= #number and i ~= #reverseNumber then
        out = out .. locale.thousandsSeperator
      end
    end

    if number[2] then
      out = number[2] .. locale.decimalSeperator .. out
    end

    return out:reverse()

  -- Text
  elseif tostring(text) then
    local translation = locale.translation[text]

    if not translation then
      if debugInfo and translation == nil and locale.id ~= DefaultLocaleId and g_game.getAccountType() >= ACCOUNT_TYPE_GAMEMASTER then
        pdebug('Unable to translate: \"' .. text .. '\"')
      end

      translation = text
    end

    return string.format(translation, ...)
  end

  return text
end



-- Client to server

function ClientLocales.sendLocale()
  if not ClientLocales.getLocale() then
    if debugInfo then
      pdebug(string.format('Current locale %d is unknown.', currentLocaleId))
    end
    return
  end

  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return false
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeLocale)
  msg:addU8(currentLocaleId)
  protocolGame:send(msg)

  return true
end
