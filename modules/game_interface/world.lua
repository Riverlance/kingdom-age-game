local worldIconWidget
local worldNameLabel

local function hideWorldInfo()
  if worldIconWidget then
    worldIconWidget:setVisible(false)
  end

  if worldNameLabel then
    worldNameLabel:setVisible(false)
  end
end

function GameInterface.updateWorldInfo()
  if not worldIconWidget or not worldNameLabel then
    return
  end

  local worldName = g_game.getWorldName()
  if not g_game.isOnline() or worldName == '' then
    hideWorldInfo()
    return
  end

  worldNameLabel:setText(f(loc'${GameInterfaceWorldLabel}', worldName))
  worldIconWidget:setVisible(true)
  worldNameLabel:setVisible(true)
end

function GameInterface.initWorld()
  connect(g_game, {
    onGameStart = GameInterface.updateWorldInfo,
    onGameEnd = hideWorldInfo,
  })
end

function GameInterface.terminateWorld()
  disconnect(g_game, {
    onGameStart = GameInterface.updateWorldInfo,
    onGameEnd = hideWorldInfo,
  })

  hideWorldInfo()
  worldIconWidget = nil
  worldNameLabel = nil
end

function GameInterface.setWorldInfoWidgets(iconWidget, nameLabel)
  worldIconWidget = iconWidget
  worldNameLabel = nameLabel
  GameInterface.updateWorldInfo()
end
