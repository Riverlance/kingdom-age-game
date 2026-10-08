g_locales.loadLocales(resolvepath(''))

_G.ClientStyles = { }



local resourceLoaders = {
  ['otui']   = g_ui.importStyle,
  ['ttf']    = g_fonts.importFont,
  ['otf']    = g_fonts.importFont,
  ['otps']   = g_particles.importParticle,
}



function ClientStyles.init()
  -- Alias
  ClientStyles.m = modules.client_styles

  local device = g_platform.getDevice()
  ClientStyles.importResources('styles', 'otui', device)
  ClientStyles.importResources('fonts', 'ttf', device)
  ClientStyles.importResources('fonts', 'otf', device)
  ClientStyles.importResources('particles', 'otps', device)

  g_mouse.loadCursors('/cursors/cursors')
  g_gameConfig.loadFonts()
end

function reloadParticles()
    g_particles.terminate()
    local device = g_platform.getDevice()
    importResources("particles", "otps", device)
end

function ClientStyles.terminate()
  _G.ClientStyles = nil
end

function ClientStyles.importResources(dir, type, device)
  local path = '/' .. dir
  local files = g_resources.listDirectoryFiles(path, true, false, true)
  for _, file in ipairs(files) do
    if g_resources.isFileType(file, type) then
      resourceLoaders[type](file)
    end
  end

  -- try load device specific resources
  if device then
    local devicePath = g_platform.getDeviceShortName(device.type)
    if devicePath ~= '' then
      table.insertall(files, ClientStyles.importResources(dir .. '/' .. devicePath, type))
    end
    local osPath = g_platform.getOsShortName(device.os)
    if osPath ~= '' then
      table.insertall(files, ClientStyles.importResources(dir .. '/' .. osPath, type))
    end
    return
  end
  return files
end
