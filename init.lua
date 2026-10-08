-- this is the first file executed when the application starts
-- we have to load the first modules from here

-- How to create a new version
-- Version *.x.x : Major Release - Significant New Systems
-- Version x.*.x : Minor Release - Improvements
-- Version x.x.* : Revision Release - Bug/Issue Fixes
CLIENT_VERSION_NAME = '1.0.1' -- [CLIENT VERSION] Here is just the Version Name

-- Setup application name
g_app.setName("Kingdom Age Online")
g_app.setCompactName("kingdomage")
g_app.setOrganizationName("Vision Games Entertainment")

-- Sets a seed for the pseudo-random generator
math.randomseed(os.time())

-- setup logger
g_logger.info('Operating system: ' .. g_platform.getOSName())

-- print first terminal message
g_logger.info(g_app.getName() .. --[[' ' .. g_app.getVersion() ..]] ' Version ' .. CLIENT_VERSION_NAME .. ' Built on ' .. g_app.getBuildDate() .. ' for arch ' .. g_app.getBuildArch())

-- setup lua debugger
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  require("lldebugger").start()
  g_logger.debug("Started LUA debugger.")
else
  g_logger.debug("LUA debugger not started (not launched with VSCode local-lua).")
end

-- add data directory to the search path
if not g_resources.addSearchPath(g_resources.getWorkDir() .. 'data', true) then
  g_logger.fatal('Unable to add data directory to the search path.')
end

-- add modules directory to the search path
if not g_resources.addSearchPath(g_resources.getWorkDir() .. 'modules', true) then
  g_logger.fatal('Unable to add modules directory to the search path.')
end

-- -- try to add mods path too
-- g_resources.addSearchPath(g_resources.getWorkDir() .. 'mods', true)

-- setup directory for saving configurations
if not g_resources.setWriteDir(g_resources.getWorkDir()) or not g_resources.makeDir('config') then
  g_logger.fatal('Unable to make config directory.')
end
g_resources.setWriteDir(g_resources.getWorkDir() .. 'config')

-- search all packages
g_resources.searchAndAddPackages('/', '.otpkg', true)

-- load settings
g_configs.loadSettings('/config.otml')

g_modules.discoverModules()

-- libraries modules 0-99
g_modules.autoLoadModules(99)
g_modules.ensureModuleLoaded('corelib')
g_modules.ensureModuleLoaded('gamelib')
g_modules.ensureModuleLoaded('kalib')

-- client modules 100-499
g_modules.autoLoadModules(499)
g_modules.ensureModuleLoaded('client')

-- game modules 500-999
g_modules.autoLoadModules(999)
g_modules.ensureModuleLoaded('game_interface')

-- mods 1000-9999
g_modules.autoLoadModules(9999)

local script = '/' .. g_app.getCompactName() .. 'rc.lua'

if g_resources.fileExists(script) then
  dofile(script)
end
