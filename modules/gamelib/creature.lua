-- @docclass Creature

-- @docconsts @{

SkullNone = 0
SkullYellow = 1
SkullGreen = 2
SkullWhite = 3
SkullRed = 4
SkullBlack = 5
SkullOrange = 6
SkullProtected = 7

ShieldNone = 0
ShieldWhiteYellow = 1
ShieldWhiteBlue = 2
ShieldBlue = 3
ShieldYellow = 4
ShieldBlueSharedExp = 5
ShieldYellowSharedExp = 6
ShieldBlueNoSharedExpBlink = 7
ShieldYellowNoSharedExpBlink = 8
ShieldBlueNoSharedExp = 9
ShieldYellowNoSharedExp = 10

EmblemNone = 0
EmblemGreen = 1
EmblemRed = 2
EmblemBlue = 3

NpcIconNone = 0
NpcIconChat = 1
NpcIconTrade = 2
NpcIconQuest = 3
NpcIconTradeQuest = 4

CreatureTypePlayer = 0
CreatureTypeMonster = 1
CreatureTypeNpc = 2
CreatureTypeSummonOwn = 3
CreatureTypeSummonOther = 4

SpecialIconNone = 0
SpecialIconWanted = 1

-- @}

function getNextSkullId(skullId)
  if skullId == SkullRed or skullId == SkullBlack then
    return SkullBlack
  end
  return SkullRed
end

function getSkullImagePath(skullId)
  local path
  if skullId == SkullYellow then
    path = '/images/game/creature/skull/yellow'
  elseif skullId == SkullGreen then
    path = '/images/game/creature/skull/green'
  elseif skullId == SkullWhite then
    path = '/images/game/creature/skull/white'
  elseif skullId == SkullRed then
    path = '/images/game/creature/skull/red'
  elseif skullId == SkullBlack then
    path = '/images/game/creature/skull/black'
  elseif skullId == SkullOrange then
    path = '/images/game/creature/skull/orange'
  elseif skullId == SkullProtected then
    path = '/images/game/creature/skull/protected'
  end
  return path
end

function getShieldImagePathAndBlink(shieldId)
  local path, blink
  if shieldId == ShieldWhiteYellow then
    path, blink = '/images/game/creature/shield/yellow_white', false
  elseif shieldId == ShieldWhiteBlue then
    path, blink = '/images/game/creature/shield/blue_white', false
  elseif shieldId == ShieldBlue then
    path, blink = '/images/game/creature/shield/blue', false
  elseif shieldId == ShieldYellow then
    path, blink = '/images/game/creature/shield/yellow', false
  elseif shieldId == ShieldBlueSharedExp then
    path, blink = '/images/game/creature/shield/blue_shared', false
  elseif shieldId == ShieldYellowSharedExp then
    path, blink = '/images/game/creature/shield/yellow_shared', false
  elseif shieldId == ShieldBlueNoSharedExpBlink then
    path, blink = '/images/game/creature/shield/blue_not_shared', true
  elseif shieldId == ShieldYellowNoSharedExpBlink then
    path, blink = '/images/game/creature/shield/yellow_not_shared', true
  elseif shieldId == ShieldBlueNoSharedExp then
    path, blink = '/images/game/creature/shield/blue_not_shared', false
  elseif shieldId == ShieldYellowNoSharedExp then
    path, blink = '/images/game/creature/shield/yellow_not_shared', false
  elseif shieldId == ShieldGray then
    path, blink = '/images/game/creature/shield/gray', false
  end
  return path, blink
end

function getEmblemImagePath(emblemId)
  local path
  if emblemId == EmblemGreen then
    path = '/images/game/creature/emblem/green'
  elseif emblemId == EmblemRed then
    path = '/images/game/creature/emblem/red'
  elseif emblemId == EmblemBlue then
    path = '/images/game/creature/emblem/blue'
  elseif emblemId == EmblemMember then
    path = '/images/game/creature/emblem/member'
  elseif emblemId == EmblemOther then
    path = '/images/game/creature/emblem/other'
  end
  return path
end

function getCreatureTypeImagePath(typeId)
  local path
  if typeId == CreatureTypeSummonOwn then
    path = '/images/game/creature/type/summon_own'
  elseif typeId == CreatureTypeSummonOther then
    path = '/images/game/creature/type/summon_other'
  end
  return path
end

function getIconImagePath(iconId)
  local path
  if iconId == NpcIconChat then
    path = '/images/game/creature/speech_bubble/chat'
  elseif iconId == NpcIconTrade then
    path = '/images/game/creature/speech_bubble/trade'
  elseif iconId == NpcIconQuest then
    path = '/images/game/creature/speech_bubble/quest'
  elseif iconId == NpcIconTradeQuest then
    path = '/images/game/creature/speech_bubble/trade_quest'
  end
  return path
end

function getSpecialIconPath(iconId)
  local path
  if iconId == SpecialIconWanted then
    path = '/images/game/creature/special_icon/wanted'
  end
  return path
end

function Creature:onSkullChange(skullId, oldSkull)
  local imagePath = getSkullImagePath(skullId)
  if imagePath then
    self:setSkullTexture(imagePath)
  end
end

function Creature:onShieldChange(shieldId)
  local imagePath, blink = getShieldImagePathAndBlink(shieldId)
  if imagePath then
    self:setShieldTexture(imagePath, blink)
  end
end

function Creature:onEmblemChange(emblemId)
  local imagePath = getEmblemImagePath(emblemId)
  if imagePath then
    self:setEmblemTexture(imagePath)
  end
end

function Creature:onTypeChange(typeId)
  local imagePath = getCreatureTypeImagePath(typeId)
  if imagePath then
    self:setTypeTexture(imagePath)
  end
end

function Creature:onIconChange(iconId)
  local imagePath = getIconImagePath(iconId)
  if imagePath then
    self:setIconTexture(imagePath)
  end
end

function Creature:onSpecialIconChange(iconId)
  local imagePath = getSpecialIconPath(iconId)
  if imagePath then
    self:setSpecialIconTexture(imagePath)
  end
end
