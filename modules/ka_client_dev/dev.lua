_G.ClientDev = { }
ClientDev.m  = modules.ka_client_dev -- Alias



local developmentWindow
local localCheckBox
local devCheckBox
local drawBoxesCheckBox
local hideMapCheckBox



local function onServerChange(self)
  if localCheckBox:isChecked() and devCheckBox:isChecked() then
    if self == localCheckBox then
      devCheckBox:setChecked(false)
    else
      localCheckBox:setChecked(false)
    end
  end
end

local function onLocalCheckBoxChange(self, value)
  if value then
    ClientEnterGame.setUniqueServer(ClientEnterGame.localIp, g_settings.get('port'), 1099)
  else
    ClientEnterGame.setUniqueServer(ClientEnterGame.clientIp, g_settings.get('port'), 1099)
  end
  onServerChange(self)
end

local function onDevCheckBoxChange(self, value)
  if value then
    ClientEnterGame.setUniqueServer(g_settings.get('host'), 7175, 1099)
  else
    ClientEnterGame.setUniqueServer(g_settings.get('host'), 7171, 1099)
  end
  onServerChange(self)
end

local function onDrawBoxesCheckBoxChange(self, value)
  draw_debug_boxes(value)
end

local function onHideMapCheckBoxChange(self, value)
  if value then
    hide_map()
  else
    show_map()
  end
end



function ClientDev.init()
  developmentWindow = g_ui.displayUI('dev')
  localCheckBox     = developmentWindow:getChildById('localCheckBox')
  devCheckBox       = developmentWindow:getChildById('devCheckBox')
  drawBoxesCheckBox = developmentWindow:getChildById('drawBoxesCheckBox')
  hideMapCheckBox   = developmentWindow:getChildById('hideMapCheckBox')

  -- Setup window
  developmentWindow:breakAnchors()
  developmentWindow:hide()
  developmentWindow:move(200, 200)

  -- Bind key
  g_keyboard.bindKeyDown('Ctrl+Alt+D', ClientDev.toggleWindow)

  -- Connect
  connect(localCheckBox, {
    onCheckChange = onLocalCheckBoxChange
  })
  connect(devCheckBox, {
    onCheckChange = onDevCheckBoxChange
  })
  connect(drawBoxesCheckBox, {
    onCheckChange = onDrawBoxesCheckBoxChange
  })
  connect(hideMapCheckBox, {
    onCheckChange = onHideMapCheckBoxChange
  })
end

function ClientDev.terminate()
  -- Disconnect
  disconnect(hideMapCheckBox, {
    onCheckChange = onHideMapCheckBoxChange
  })
  disconnect(drawBoxesCheckBox, {
    onCheckChange = onDrawBoxesCheckBoxChange
  })
  disconnect(devCheckBox, {
    onCheckChange = onDevCheckBoxChange
  })
  disconnect(localCheckBox, {
    onCheckChange = onLocalCheckBoxChange
  })

  -- Unbind key
  g_keyboard.unbindKeyDown('Ctrl+Alt+D')

  -- Destroy window
  if developmentWindow then
    developmentWindow:destroy()
    developmentWindow = nil
  end
  localCheckBox     = nil
  devCheckBox       = nil
  drawBoxesCheckBox = nil
  hideMapCheckBox   = nil

  -- Set IP to default server
  ClientEnterGame.setUniqueServer(ClientEnterGame.clientIp, 7171, 1099)

  _G.ClientDev = nil
end



function ClientDev.toggleWindow()
  if developmentWindow:isHidden() then
    developmentWindow:show()
  else
    developmentWindow:hide()
  end

  -- Connect to local server by default
  localCheckBox:setChecked(true)
end
