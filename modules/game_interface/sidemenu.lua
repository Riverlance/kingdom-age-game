local leftSideMenu
local rightSideMenu
local leftSideMenuButton
local rightSideMenuButton



local function setSideMenuVisibility(sideMenu, button, visible)
  sideMenu:setOn(visible)
  button:setOn(visible)
  sideMenu:updateLayout()
end

function GameInterface.initSideMenu(leftMenu, rightMenu)
  leftSideMenu = leftMenu
  rightSideMenu = rightMenu
  leftSideMenuButton = leftMenu:getParent():getChildById('leftSideMenuButton')
  rightSideMenuButton = rightMenu:getParent():getChildById('rightSideMenuButton')

  GameInterface.setLeftSideMenu()
  GameInterface.setRightSideMenu()
end

function GameInterface.terminateSideMenu()
  leftSideMenu = nil
  rightSideMenu = nil
  leftSideMenuButton = nil
  rightSideMenuButton = nil
end

function GameInterface.setLeftSideMenu(visible)
  if visible == nil then
    visible = ClientOptions.getOption('showLeftSideMenu')
  end

  setSideMenuVisibility(leftSideMenu, leftSideMenuButton, visible)
end

function GameInterface.setRightSideMenu(visible)
  if visible == nil then
    visible = ClientOptions.getOption('showRightSideMenu')
  end

  setSideMenuVisibility(rightSideMenu, rightSideMenuButton, visible)
end
