local locale = {
  id           = Locale.En,
  name         = 'en',
  languageName = 'English',
  -- charset      = 'cp1252',

  formatNumbers      = true,
  decimalSeperator   = '.',
  thousandsSeperator = ',',

  translation = { }, -- Empty because everything is in english already
}

ClientLocales.installLocale(locale)
