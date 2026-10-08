function g_game.getRsa()
  return G.currentRsa
end

function g_game.findPlayerItem(itemId, subType)
  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    for slot = InventorySlotFirst, InventorySlotLast do
      local item = localPlayer:getInventoryItem(slot)
      if item and item:getId() == itemId and (subType == -1 or item:getSubType() == subType) then
        return item
      end
    end
  end
  return g_game.findItemInContainers(itemId, subType)
end

function g_game.chooseRsa(host)
  if G.currentRsa ~= CIPSOFT_RSA and G.currentRsa ~= OTSERV_RSA then
    return
  end

  if host:ends('.tibia.com') or host:ends('.cipsoft.com') then
    g_game.setRsa(CIPSOFT_RSA)

    if g_app.getOs() == 'windows' then
      g_game.setCustomOs(OsTypes.Windows)
    else
      g_game.setCustomOs(OsTypes.Linux)
    end
  else
    if G.currentRsa == CIPSOFT_RSA then
      g_game.setCustomOs(-1)
    end
    g_game.setRsa(OTSERV_RSA)
  end
end

function g_game.setRsa(rsa, e)
  e = e or '65537'
  g_crypt.rsaSetPublicKey(rsa, e)
  G.currentRsa = rsa
end

function g_game.isOfficialTibia()
  return G.currentRsa == CIPSOFT_RSA
end

function g_game.getSupportedClients()
  return { DefaultClientVersion }
end

if not G.currentRsa then
  g_game.setRsa(OTSERV_RSA)
end

function g_game.getWidgetByPos(mousePos, wantsPhantom, parentWidget)
  if wantsPhantom == nil then
    wantsPhantom = false
  end
  parentWidget = parentWidget or rootWidget

  local mousePosition = mousePos or g_window.getMousePosition()
  return parentWidget:recursiveGetChildByPos(mousePosition, wantsPhantom), mousePosition
end
