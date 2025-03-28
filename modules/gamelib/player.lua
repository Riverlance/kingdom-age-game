-- @docclass Player

PlayerStates = {
  None = 0,
  Poison = 1,
  Burn = 2,
  Energy = 4,
  Drunk = 8,
  ManaShield = 16,
  Paralyze = 32,
  Haste = 64,
  Swords = 128,
  Drowning = 256,
  Freezing = 512,
  Dazzled = 1024,
  Cursed = 2048,
  PartyBuff = 4096,
  PZBlock = 8192,
  Secure = 16384,
  Bleeding = 32768,
  Hungry = 65536,
  SecureBlock = 131072,
  PZ = 262144,
  WZ = 524288,
  RZ = 1048576,
  BZ = 2097152
}

InventorySlotOther = 0
InventorySlotHead = 1
InventorySlotNeck = 2
InventorySlotBack = 3
InventorySlotBody = 4
InventorySlotRight = 5
InventorySlotLeft = 6
InventorySlotLeg = 7
InventorySlotFeet = 8
InventorySlotFinger = 9
InventorySlotAmmo = 10
InventorySlotInbox = 11

InventorySlotFirst = 1
InventorySlotLast = 11

function Player:getCharacterInfo()
  return ClientCharacterList.getCharacterInfoByName(self:getName())
end

function isPartyLeader(shield)
  return shield == ShieldWhiteYellow or
         shield == ShieldYellow or
         shield == ShieldYellowSharedExp or
         shield == ShieldYellowNoSharedExpBlink or
         shield == ShieldYellowNoSharedExp
end

function Player:isPartyLeader()
  return isPartyLeader(self:getShield())
end

function isPartyMember(shield)
  return shield == ShieldWhiteYellow or
         shield == ShieldYellow or
         shield == ShieldYellowSharedExp or
         shield == ShieldYellowNoSharedExpBlink or
         shield == ShieldYellowNoSharedExp or
         shield == ShieldBlueSharedExp or
         shield == ShieldBlueNoSharedExpBlink or
         shield == ShieldBlueNoSharedExp or
         shield == ShieldBlue
end

function Player:isPartyMember()
  return isPartyMember(self:getShield())
end

function isPartySharedExperienceActive(shield)
  return shield == ShieldYellowSharedExp or
         shield == ShieldYellowNoSharedExpBlink or
         shield == ShieldYellowNoSharedExp or
         shield == ShieldBlueSharedExp or
         shield == ShieldBlueNoSharedExpBlink or
         shield == ShieldBlueNoSharedExp
end

function Player:isPartySharedExperienceActive()
  return isPartySharedExperienceActive(self:getShield())
end

function Player:hasVip(creatureName)
  for _, vip in pairs(g_game.getVips()) do
    if vip[1] == creatureName then
      return true
    end
  end
  return false
end

function Player:isMounted()
  local outfit = self:getOutfit()
  return outfit.mount ~= nil and outfit.mount > 0
end

function Player:toggleMount()
  if g_game.getFeature(GamePlayerMounts) then
    g_game.mount(not self:isMounted())
  end
end

function Player:mount()
  if g_game.getFeature(GamePlayerMounts) then
    g_game.mount(true)
  end
end

function Player:dismount()
  if g_game.getFeature(GamePlayerMounts) then
    g_game.mount(false)
  end
end

function Player:getItem(itemId, subType)
  return g_game.findPlayerItem(itemId, subType or -1)
end

function Player:getItems(itemId, subType)
  local subType = subType or -1

  local items = { }
  for i = InventorySlotFirst, InventorySlotLast do
    local item = self:getInventoryItem(i)
    if item and item:getId() == itemId and (subType == -1 or item:getSubType() == subType) then
      table.insert(items, item)
    end
  end

  for _, container in pairs(g_game.getContainers()) do
    for _, item in pairs(container:getItems()) do
      if item:getId() == itemId and (subType == -1 or item:getSubType() == subType) then
        item.container = container
        table.insert(items, item)
      end
    end
  end
  return items
end

function Player:getItemsCount(itemId)
  local items, count = self:getItems(itemId), 0
  for i = 1, #items do
    count = count + items[i]:getCount()
  end
  return count
end

function Player:hasState(state, states)
  if not states then
    states = self:getStates()
  end

  for i = 1, 32 do
    local pow = math.pow(2, i - 1)
    if pow > states then
      break
    end

    local states = bit.band(states, pow)
    if states == state then
      return true
    end
  end
  return false
end
