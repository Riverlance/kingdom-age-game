--[[
  * Polish signs: https://github.com/otland/otclient/pull/6
  * See also: https://egzot.github.io/otclient-font-create-tool
]]

g_locales = { }



local debugInfo = false



Locale = {
  En    = 1,
  PtBr  = 2,
  PtPt  = 3,
  Es419 = 4,
  EsEs  = 5,
  Pl    = 6,
  Ru    = 7,
  Sv    = 8,
  Nb    = 9,
  De    = 10,
  Nlnl  = 11,
  Frfr  = 12,
  Fi    = 13,
  It    = 14,
  ZhCn  = 15,
  Ja    = 16,
  Ko    = 17,
}
Locale.First = Locale.En
Locale.Last  = Locale.Ko

Locales = {
  [Locale.En]    = 'en',
  [Locale.PtBr]  = 'ptbr',
  [Locale.PtPt]  = 'ptpt',
  [Locale.Es419] = 'es419',
  [Locale.EsEs]  = 'eses',
  [Locale.Pl]    = 'pl',
  [Locale.Ru]    = 'ru',
  [Locale.Sv]    = 'sv',
  [Locale.Nb]    = 'nb',
  [Locale.De]    = 'de',
  [Locale.Nlnl]  = 'nlnl',
  [Locale.Frfr]  = 'frfr',
  [Locale.Fi]    = 'fi',
  [Locale.It]    = 'it',
  [Locale.ZhCn]  = 'zhcn',
  [Locale.Ja]    = 'ja',
  [Locale.Ko]    = 'ko',
}



InstalledLocales = nil

DefaultLocaleId = Locale.En
CurrentLocaleId = DefaultLocaleId



function UIWidget:updateLocale(params)
  local par = type(params) == 'function' and params(self) or params
  if self.loc then self:setText(loc(self.loc, par), false) end
  if self.loct then self:setTooltip(loc(self.loct, par), self:getTooltipType()) end
end

function UIWidget:onLocaleChange(localeId, prevLocaleId)
  self:updateLocale()
  for _, child in ipairs(self:getChildren() or { }) do
    child:onLocaleChange(localeId, prevLocaleId)
  end
end



function g_locales.getInstalledLocales()
  return InstalledLocales
end

function g_locales.installLocale(locale)
  if not locale or not locale.id then
    error('Unable to install locale.')
  end

  local installedLocale = InstalledLocales[locale.id]
  if installedLocale then
    return -- Installed already
  end

  -- Set up
  InstalledLocales[locale.id] = locale
end

function g_locales.installLocales()
  dofiles('/locales')
end

function g_locales.getLocale()
  return InstalledLocales[CurrentLocaleId]
end

function g_locales.setLocale(id)
  local locale = InstalledLocales[id]

  if not locale then
    error(f('Locale %d does not exist.', id))

  elseif locale == g_locales.getLocale() then
    g_settings.set('locale', id)
    if g_fonts and g_fonts.setCjkVariant then
      g_fonts.setCjkVariant(locale.cjkVariant or 'default')
    end
    return
  end

  local prevLocaleId = CurrentLocaleId
  CurrentLocaleId    = id
  g_settings.set('locale', id)

  if g_fonts and g_fonts.setCjkVariant then
    g_fonts.setCjkVariant(locale.cjkVariant or 'default')
  end

  rootWidget:onLocaleChange(id, prevLocaleId)

  g_locales.sendLocale()

  if debugInfo then
    pdebug(f('Using configured locale: %d', id))
  end
end

-- Client to server

function g_locales.sendLocale()
  if not g_locales.getLocale() then
    if debugInfo then
      pdebug(f('Current locale %d is unknown.', CurrentLocaleId))
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
  msg:addU8(CurrentLocaleId)
  protocolGame:send(msg)

  return true
end



g_locales.translationList = { }

function g_locales.getTranslation(id)
  local lang = Locales[CurrentLocaleId]
  local tr = g_locales.translationList[id]
  local selected = tr and (tr[lang] or tr['en']) or nil-- default: English
  if type(selected) == 'table' then
    return selected[math.random(#selected)]
  else
    return selected
  end
end

function g_locales.addTranslations(tr, overwrite) -- { id = { [lang] = text, ... }, ...}
  if overwrite == nil then
    overwrite = true
  end

  for id, trList in pairs(tr) do
    if overwrite then
      -- Registered already
      if g_locales.translationList[id] then
        print_traceback(f('Duplicated translation: "%s"', g_locales.translationList[id][Locales[1]]))
      else
        g_locales.translationList[id] = trList
      end

    else
      -- Not registered yet
      if not g_locales.translationList[id] then
        print_traceback(f('No translation found for key: "%s"', id))
      else
        for locale, str in pairs(trList) do
          g_locales.translationList[id][locale] = str
        end
      end
    end
  end
end

function _G.loc(str, params)
  local locale = g_locales.getLocale()
  if not locale then
    return str
  end

  -- Number
  if tonumber(str) and locale.formatNumbers then
    local number        = tostring(str) / '.'
    local reverseNumber = number[1]:reverse()
    local out           = ''

    for i = 1, #reverseNumber do
      out = out .. reverseNumber:sub(i, i)
      if i % 3 == 0 and i ~= #number and i ~= #reverseNumber then
        out = out .. locale.thousandsSeparator
      end
    end

    if number[2] then
      out = number[2] .. locale.decimalSeparator .. out
    end

    return out:reverse()
  end

  -- String
  local ret = tostring(str):eval(function(s) return loc(g_locales.getTranslation(s) or (params and params[s]) or _G.s, params) end)
  if ret == 'nil' and tostring(str) ~= 'nil' then -- Translation failed now and not failed before
    print_traceback(f('No translation found for: "%s"', str))
  end
  return ret
end

function g_locales.loadLocales(path)
  dofile(f('%sloc.lua', path))
end





function g_locales.init()
  InstalledLocales = { }

  g_locales.installLocales()

  local localeId = tonumber(g_settings.get('locale'))
  g_locales.setLocale(localeId or DefaultLocaleId)

  connect(g_game, {
    onGameStart = g_locales.onGameStart
  })
end

function g_locales.terminate() -- not in use at the moment
  InstalledLocales = nil

  disconnect(g_game, {
    onGameStart = g_locales.onGameStart
  })

end

function g_locales.onGameStart()
  g_locales.sendLocale()
end

g_locales.init()
