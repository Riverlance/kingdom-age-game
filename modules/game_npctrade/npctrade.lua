_G.GameNpcTrade = { }



local backpackSize  = 20
local backpackPrice = 20

TradeNoError               = 0
TradeUnknownError          = 1
TradeErrorNoEnoughMoney    = 2
TradeErrorNoEnoughCapacity = 3
TradeErrorNoEnoughTrust    = 4
TradeErrorItemNotFound     = 5

TradeErrorStr = {
  [TradeUnknownError]          = 'You cannot trade this item.',
  [TradeErrorNoEnoughMoney]    = 'You have no enough money for trade this item.',
  [TradeErrorNoEnoughCapacity] = 'You have no enough capacity for trade this item.',
  [TradeErrorNoEnoughTrust]    = 'You have no enough trust in this city for trade this item.',
  [TradeErrorItemNotFound]     = "You don't have this item.",
}

BUY = 1
SELL = 2
CURRENCY = 'GPs'
CURRENCY_DECIMAL = false
CURRENCY_VIP = 'KAps'
CURRENCY_ISVIP = false
WEIGHT_UNIT = 'oz'
LAST_INVENTORY = 10

npcWindow = nil
itemsPanelListScrollBar = nil
itemsPanel = nil
radioTabs = nil
radioItems = nil
searchText = nil
setupPanel = nil
quantity = nil
quantityScroll = nil
nameLabel = nil
priceLabel = nil
moneyLabel = nil
weightDesc = nil
weightLabel = nil
capacityDesc = nil
capacityLabel = nil
trustDesc = nil
trustLabel = nil
tradeButton = nil
buyTab = nil
sellTab = nil
initialized = false

buyWithBackpack = nil
ignoreCapacity = nil
ignoreEquipped = nil
showAllItems = nil
sellAllButton = nil

playerFreeCapacity = 0
playerIsPremium = false
playerMoneyFromBank = true
playerMoney = 0
tradeItems = { }
playerItems = { }
selectedItem = nil

townId                    = 0
trustMaxLevel             = 0
townTrustLevel            = 0
townTrustExperience       = 0
townTrustExpOfActualLevel = 0
townTrustExpToNextLevel   = 0

local howToTownTrust = [[Some items, like equipments, can be bought if you have enough money and trust.
Higher trust levels unlocks access to buy new items.
Your trust of each city increases individually by selling some items and decreases over time.]] -- See achievements on server

local function getTownStr()
  return townId > 0 and TownStr[townId] and ' (' .. TownStr[townId] .. ' City)' or ''
end

cancelNextRelease = nil

function GameNpcTrade.init()
  -- Alias
  GameNpcTrade.m = modules.game_npctrade

  npcWindow = g_ui.displayUI('npctrade')
  npcWindow:setVisible(false)

  itemsPanelListScrollBar = npcWindow:recursiveGetChildById('itemsPanelListScrollBar')

  itemsPanel = npcWindow:recursiveGetChildById('itemsPanel')
  searchText = npcWindow:recursiveGetChildById('searchText')

  setupPanel = npcWindow:getChildById('setupPanel')
  quantityScroll = setupPanel:getChildById('quantityScroll')
  nameLabel = setupPanel:getChildById('name')
  priceLabel = setupPanel:getChildById('price')
  moneyLabel = setupPanel:getChildById('money')
  weightDesc = setupPanel:getChildById('weightDesc')
  weightLabel = setupPanel:getChildById('weight')
  capacityDesc = setupPanel:getChildById('capacityDesc')
  capacityLabel = setupPanel:getChildById('capacity')
  trustDesc = setupPanel:getChildById('trustDesc')
  trustLabel = setupPanel:getChildById('trust')
  tradeButton = npcWindow:recursiveGetChildById('tradeButton')

  buyWithBackpack = npcWindow:recursiveGetChildById('buyWithBackpack')
  ignoreCapacity = npcWindow:recursiveGetChildById('ignoreCapacity')
  ignoreEquipped = npcWindow:recursiveGetChildById('ignoreEquipped')
  showAllItems = npcWindow:recursiveGetChildById('showAllItems')
  sellAllButton = npcWindow:recursiveGetChildById('sellAllButton')

  buyTab = npcWindow:getChildById('buyTab')
  sellTab = npcWindow:getChildById('sellTab')

  radioTabs = UIRadioGroup.create()
  radioTabs:addWidget(buyTab)
  radioTabs:addWidget(sellTab)
  radioTabs:selectWidget(buyTab)
  radioTabs.onSelectionChange = GameNpcTrade.onTradeTypeChange

  cancelNextRelease = false

  if g_game.isOnline() then
    playerFreeCapacity = g_game.getLocalPlayer():getFreeCapacity()
  end

  connect(g_game, {
    onGameEnd       = GameNpcTrade.hide,
    onOpenNpcTrade  = GameNpcTrade.onOpenNpcTrade,
    onCloseNpcTrade = GameNpcTrade.onCloseNpcTrade,
    onPlayerGoods   = GameNpcTrade.onPlayerGoods
  })

  connect(LocalPlayer, {
    onFreeCapacityChange = GameNpcTrade.onFreeCapacityChange,
    onInventoryChange    = GameNpcTrade.onInventoryChange
  })

  initialized = true
end

function GameNpcTrade.terminate()
  initialized = false
  npcWindow:destroy()

  disconnect(g_game, {
    onGameEnd       = GameNpcTrade.hide,
    onOpenNpcTrade  = GameNpcTrade.onOpenNpcTrade,
    onCloseNpcTrade = GameNpcTrade.onCloseNpcTrade,
    onPlayerGoods   = GameNpcTrade.onPlayerGoods
  })

  disconnect(LocalPlayer, {
    onFreeCapacityChange = GameNpcTrade.onFreeCapacityChange,
    onInventoryChange    = GameNpcTrade.onInventoryChange
  })

  _G.GameNpcTrade = nil
end

function GameNpcTrade.show()
  if g_game.isOnline() then
    if #tradeItems[BUY] > 0 then
      radioTabs:selectWidget(buyTab)
    else
      radioTabs:selectWidget(sellTab)
    end

    npcWindow:show()
    npcWindow:raise()
    npcWindow:focus()

    itemsPanelListScrollBar:setValue(0)
  end
end

function GameNpcTrade.hide()
  npcWindow:hide()
end

function GameNpcTrade.onItemBoxChecked(widget)
  if widget:isChecked() then
    local item = widget.item
    selectedItem = item
    GameNpcTrade.refreshItem(item)
    tradeButton:enable()

    if GameNpcTrade.getCurrentTradeType() == SELL then
      quantityScroll:setValue(quantityScroll:getMinimum())
    else
      quantityScroll:setValue(quantityScroll:getMinimum())
    end
  end
end

function GameNpcTrade.onQuantityValueChange(quantity)
  if not selectedItem then
    return
  end

  local tradeType = GameNpcTrade.getCurrentTradeType()

  local items, backpacks, price = GameNpcTrade.getBuyAmount(selectedItem, quantity)
  priceLabel:setText(GameNpcTrade.formatCurrency(price) .. GameNpcTrade.formatTrust(selectedItem) .. GameNpcTrade.formatTown(selectedItem))
  weightLabel:setText(tradeType == BUY and string.format('%.2f', quantity * selectedItem.weight) .. ' ' .. WEIGHT_UNIT or '')

  GameNpcTrade.checkTradeTooltip()
end

function GameNpcTrade.onTradeTypeChange(radioTabs, selected, deselected)
  tradeButton:setText(selected:getText())
  selected:setOn(true)
  deselected:setOn(false)

  local currentTradeType = GameNpcTrade.getCurrentTradeType()
  buyWithBackpack:setVisible(currentTradeType == BUY)
  ignoreCapacity:setVisible(currentTradeType == BUY)
  ignoreEquipped:setVisible(currentTradeType == SELL)
  showAllItems:setVisible(currentTradeType == SELL)
  sellAllButton:setVisible(currentTradeType == SELL)

  GameNpcTrade.refreshTradeItems()
  GameNpcTrade.refreshPlayerGoods()

  itemsPanelListScrollBar:setValue(0)
end

function GameNpcTrade.onTradeClick()
  if GameNpcTrade.getCurrentTradeType() == BUY then
    g_game.buyItem(selectedItem.ptr, selectedItem.maskptr, selectedItem.maskOutfitType, selectedItem.maskOutfitMount, quantityScroll:getValue(), ignoreCapacity:isChecked(), buyWithBackpack:isChecked())
  else
    g_game.sellItem(selectedItem.ptr, selectedItem.maskptr, selectedItem.maskOutfitType, selectedItem.maskOutfitMount, quantityScroll:getValue(), ignoreEquipped:isChecked())
  end
end

function GameNpcTrade.onSearchTextChange()
  GameNpcTrade.refreshPlayerGoods()
end

function GameNpcTrade.itemPopup(self, mousePosition, mouseButton)
  if cancelNextRelease then
    cancelNextRelease = false
    return false
  end

  local onLook = function() return g_game.inspectNpcTrade(self:getItem()) end
  if ((g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton)
    or (g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton)) then
    cancelNextRelease = true
    onLook()
    return true
  elseif mouseButton == MouseRightButton then
    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)
    menu:addOption(tr('Look'), onLook, '(Shift)')
    menu:display(mousePosition)
    return true
  elseif mouseButton == MouseLeftButton and g_keyboard.isShiftPressed() then
    onLook()
    return true
  end
  return false
end

function GameNpcTrade.onBuyWithBackpackChange()
  if selectedItem then
    GameNpcTrade.refreshItem(selectedItem)
  end
end

function GameNpcTrade.onIgnoreCapacityChange()
  GameNpcTrade.refreshPlayerGoods()
end

function GameNpcTrade.onIgnoreEquippedChange()
  GameNpcTrade.refreshPlayerGoods()
end

function GameNpcTrade.onShowAllItemsChange()
  GameNpcTrade.refreshPlayerGoods()
end

function GameNpcTrade.setCurrency(currency, decimal, isVip)
  CURRENCY = currency
  CURRENCY_DECIMAL = decimal
  CURRENCY_ISVIP = isVip
end

function GameNpcTrade.clearSelectedItem()
  nameLabel:clearText()
  weightLabel:clearText()
  priceLabel:clearText()
  tradeButton:disable()
  quantityScroll:setMinimum(0)
  quantityScroll:setMaximum(0)
  if selectedItem then
    radioItems:selectWidget(nil)
    selectedItem = nil
  end
end

function GameNpcTrade.getCurrentTradeType()
  if tradeButton:getText() == tr('Buy') then
    return BUY
  else
    return SELL
  end
end

function GameNpcTrade.getSellQuantity(item)
  if not item or not playerItems[item:getId()] then
    return 0
  end

  local removeAmount = 0
  if ignoreEquipped:isChecked() then
    local localPlayer = g_game.getLocalPlayer()
    for i=1,LAST_INVENTORY do
      local inventoryItem = localPlayer:getInventoryItem(i)
      if inventoryItem and inventoryItem:getId() == item:getId() then
        removeAmount = removeAmount + inventoryItem:getCount()
      end
    end
  end

  return playerItems[item:getId()] - removeAmount
end

function GameNpcTrade.canTradeItem(item)
  local tradeType = GameNpcTrade.getCurrentTradeType()

  if tradeType == BUY then
    if townTrustLevel < item.tradeTrustLevel then
      return TradeErrorNoEnoughTrust
    end

    local items, backpacks, price = GameNpcTrade.getBuyAmount(item, 1)
    local isIgnoreCapacityChecked = ignoreCapacity:isChecked()

    if price < 0 then
      return TradeUnknownError
    elseif playerMoney < price then
      return TradeErrorNoEnoughMoney
    elseif not isIgnoreCapacityChecked and playerFreeCapacity < item.weight then
      return TradeErrorNoEnoughCapacity
    end

  elseif tradeType == SELL then
    local items, price = GameNpcTrade.getSellAmount(item)

    if price < 0 then
      return TradeUnknownError
    elseif items < 1 then
      return TradeErrorItemNotFound
    end
  end

  return TradeNoError
end

function GameNpcTrade.refreshItem(item)
  local tradeType = GameNpcTrade.getCurrentTradeType()
  local quantity  = quantityScroll:getValue()

  local items, backpacks, price    = 0, 0, 0
  local _items, _backpacks, _price = 0, 0, 0
  if tradeType == BUY then
    items, backpacks, price = GameNpcTrade.getBuyAmount(item)
    _items, _backpacks, _price = GameNpcTrade.getBuyAmount(item, quantity)
  else
    items, price = GameNpcTrade.getSellAmount(item)
  end

  nameLabel:setText(item.name)
  priceLabel:setText(GameNpcTrade.formatCurrency(GameNpcTrade.getCurrentTradeType() == BUY and _price ~= 0 and _price or quantity * item.price) .. GameNpcTrade.formatTrust(item) .. GameNpcTrade.formatTown(item))
  weightLabel:setText(tradeType == BUY and string.format('%.2f', quantity * item.weight) .. ' ' .. WEIGHT_UNIT or '')
  quantityScroll:setMinimum(items ~= 0 and 1 or 0)
  quantityScroll:setMaximum(items)

  setupPanel:enable()

  GameNpcTrade.checkTradeTooltip()
end

function GameNpcTrade.refreshTradeItems()
  local layout = itemsPanel:getLayout()
  layout:disableUpdates()

  GameNpcTrade.clearSelectedItem()

  searchText:clearText()
  setupPanel:disable()
  itemsPanel:destroyChildren()

  if radioItems then
    radioItems:destroy()
  end
  radioItems = UIRadioGroup.create()

  local localPlayer           = g_game.getLocalPlayer()
  local localPlayerOutfit     = localPlayer:getOutfit()
  local localPlayerOutfitType = localPlayerOutfit.type

  local currentTradeItems = tradeItems[GameNpcTrade.getCurrentTradeType()]
  for _,item in pairs(currentTradeItems) do
    local npcItemBox = g_ui.createWidget('NPCItemBox', itemsPanel)

    local itemBox = npcItemBox:getChildById('itemBox')
    itemBox.item  = item

    local text = item.name
    text       = text .. '\n' .. GameNpcTrade.formatCurrency(item.price) .. GameNpcTrade.formatTrust(item)
    text       = text .. '\n' .. (string.format('%.2f', item.weight) .. ' ' .. WEIGHT_UNIT)
    itemBox:setText(text)

    local infoWidget       = npcItemBox:getChildById('infoButton')
    local tooltipText      = string.format('Name: %s', item.name)
    tooltipText            = tooltipText .. '\n' .. 'Price' .. ': ' .. GameNpcTrade.formatCurrency(item.price) .. GameNpcTrade.formatTrust(item) .. GameNpcTrade.formatTown(item)
    tooltipText            = tooltipText .. '\n' .. 'Weight' .. ': ' .. string.format('%.2f', item.weight) .. ' ' .. WEIGHT_UNIT
    infoWidget.tooltipText = tooltipText
    infoWidget:setTooltip(tooltipText, TooltipType.textBlock)

    local outfitWidget = itemBox:getChildById('outfit')
    local itemWidget   = itemBox:getChildById('item')

    if item.maskOutfitType ~= 0 or item.maskOutfitMount ~= 0 then
      if item.maskOutfitType ~= 0 then
        localPlayerOutfit.type = item.maskOutfitType
        localPlayerOutfit.mount = 0
      elseif item.maskOutfitMount ~= 0 then
        localPlayerOutfit.type  = localPlayerOutfitType
        localPlayerOutfit.mount = item.maskOutfitMount
      end
      outfitWidget:setOutfit(localPlayerOutfit)

      itemWidget:hide()
    else
      itemWidget:setItem(item.maskptr or item.ptr)
      itemWidget.onMouseRelease = GameNpcTrade.itemPopup

      outfitWidget:hide()
    end

    radioItems:addWidget(itemBox)
  end

  layout:enableUpdates()
  layout:update()
end

function GameNpcTrade.refreshPlayerGoods()
  if not initialized then
    return
  end

  GameNpcTrade.checkTradeTooltip()
  GameNpcTrade.checkSellAllTooltip()

  moneyLabel:setText(string.format('%s (%s)', GameNpcTrade.formatCurrency(playerMoney), playerMoneyFromBank and 'from bank' or 'holding'))
  if CURRENCY_ISVIP then
    moneyLabel:setTooltip(tr('Your VIP money may not be displayed correctly if points were added through the website while keeping the trade window opened.'), TooltipType.textBlock)
    buyWithBackpack:setTooltip('This option is disabled on VIP Shop.', TooltipType.textBlock)
  else
    moneyLabel:removeTooltip()
    buyWithBackpack:removeTooltip()
  end
  capacityLabel:setText(string.format('%.2f', playerFreeCapacity) .. ' ' .. WEIGHT_UNIT)
  trustLabel:setText(string.format('Level %d (%s XP)', townTrustLevel, tostring(townTrustExperience):comma()))
  local trustInfoMessage = ''
  if townTrustLevel < trustMaxLevel then
    local trustExpDiff      = townTrustExpToNextLevel - townTrustExpOfActualLevel
    local trustExpToAdvance = townTrustExpToNextLevel - townTrustExperience
    local trustExpPercent   = (trustExpToAdvance / trustExpDiff) * 100
    trustInfoMessage        = string.format('Remaining %.2f%% (about %s XP) to advance to trust level %d%s.', trustExpPercent, tostring(trustExpToAdvance):comma(), townTrustLevel + 1, getTownStr())
  else
    trustInfoMessage = string.format('You are on the maximum trust level%s.', getTownStr())
  end
  trustLabel:setTooltip(trustInfoMessage .. '\n\n' .. howToTownTrust, TooltipType.textBlock)

  local currentTradeType = GameNpcTrade.getCurrentTradeType()
  local searchFilter = searchText:getText():lower()
  local foundSelectedItem = false

  local items = itemsPanel:getChildCount()
  for i = 1, items do
    local npcItemBox = itemsPanel:getChildByIndex(i)
    local itemBox    = npcItemBox.itemBox
    local item       = itemBox.item
    local outfit     = itemBox.outfit

    local canTrade = GameNpcTrade.canTradeItem(item) == TradeNoError
    itemBox:setOn(canTrade)
    itemBox:setEnabled(canTrade)
    outfit:setOn(canTrade)

    local searchCondition = (searchFilter == '') or (searchFilter ~= '' and string.find(item.name:lower(), searchFilter) ~= nil)
    local showAllItemsCondition = (currentTradeType == BUY) or (showAllItems:isChecked()) or (currentTradeType == SELL and not showAllItems:isChecked() and canTrade)
    npcItemBox:setVisible(searchCondition and showAllItemsCondition)

    local tradeRet    = GameNpcTrade.canTradeItem(item)
    local infoWidget  = npcItemBox:getChildById('infoButton')
    local tooltipText = infoWidget.tooltipText .. (tradeRet ~= TradeNoError and TradeErrorStr[tradeRet] and '\n\n' .. TradeErrorStr[tradeRet] or '')
    infoWidget:setTooltip(tooltipText, TooltipType.textBlock)

    if selectedItem == item and npcItemBox:isVisible() and itemBox:isEnabled() then
      foundSelectedItem = true
    end
  end

  if not foundSelectedItem then
    GameNpcTrade.clearSelectedItem()
  end

  if selectedItem then
    GameNpcTrade.refreshItem(selectedItem)
  end
end

function GameNpcTrade.onOpenNpcTrade(items, _townId, _trustMaxLevel, isVip)
  tradeItems[BUY]  = { }
  tradeItems[SELL] = { }

  for _,item in pairs(items) do
    if item[9] > 0 then
      table.insert(tradeItems[BUY], {
        ptr             = item[1],
        maskptr         = item[2],
        maskOutfitType  = item[3],
        maskOutfitMount = item[4],
        name            = item[5],
        weight          = item[6] / 100,
        addTrustOnSell  = item[7],
        tradeTrustLevel = item[8],

        price           = item[9],
      })
    end

    if item[10] > 0 then
      table.insert(tradeItems[SELL], {
        ptr             = item[1],
        maskptr         = item[2],
        maskOutfitType  = item[3],
        maskOutfitMount = item[4],
        name            = item[5],
        weight          = item[6] / 100,
        addTrustOnSell  = item[7],
        tradeTrustLevel = item[8],

        price           = item[10],
      })
    end
  end

  townId         = _townId
  trustMaxLevel  = _trustMaxLevel
  CURRENCY_ISVIP = isVip

  GameNpcTrade.refreshTradeItems()
  addEvent(GameNpcTrade.show) -- player goods has not been parsed yet
end

function GameNpcTrade.closeNpcTrade()
  g_game.closeNpcTrade()
  GameNpcTrade.hide()
end

function GameNpcTrade.onCloseNpcTrade()
  GameNpcTrade.hide()
end

function GameNpcTrade.onPlayerGoods(isPremium, bankPaymentMode, money, bankMoney, kaps, _townTrustLevel, _townTrustExperience, _townTrustExpOfActualLevel, _townTrustExpToNextLevel, items)
  playerMoneyFromBank = false
  playerIsPremium     = isPremium
  playerMoney         = money

  if CURRENCY_ISVIP then
    playerMoney = kaps
  elseif isPremium and bankPaymentMode then
    playerMoneyFromBank = bankPaymentMode
    playerMoney         = bankMoney
  end

  playerItems = { }
  for _,item in pairs(items) do
    local id = item[1]:getId()
    if not playerItems[id] then
      playerItems[id] = item[2]
    else
      playerItems[id] = playerItems[id] + item[2]
    end
  end

  townTrustLevel            = _townTrustLevel
  townTrustExperience       = _townTrustExperience
  townTrustExpOfActualLevel = _townTrustExpOfActualLevel
  townTrustExpToNextLevel   = _townTrustExpToNextLevel

  GameNpcTrade.refreshPlayerGoods()
end

function GameNpcTrade.onFreeCapacityChange(localPlayer, freeCapacity, oldFreeCapacity)
  playerFreeCapacity = freeCapacity

  if npcWindow:isVisible() then
    GameNpcTrade.refreshPlayerGoods()
  end
end

function GameNpcTrade.onInventoryChange(inventory, item, oldItem)
  GameNpcTrade.refreshPlayerGoods()
end

function GameNpcTrade.getTradeItemData(id, type)
  if table.empty(tradeItems[type]) then
    return false
  end

  if type then
    for _,item in pairs(tradeItems[type]) do
      if item.ptr and item.ptr:getId() == id then
        return item
      end
    end
  else
    for _,items in pairs(tradeItems) do
      for _,item in pairs(items) do
        if item.ptr and item.ptr:getId() == id then
          return item
        end
      end
    end
  end
  return false
end

function GameNpcTrade.checkTradeTooltip()
  if not selectedItem then
    tradeButton:removeTooltip()
    return
  end
  local tradeType = GameNpcTrade.getCurrentTradeType()

  local quantity                = quantityScroll:getValue()
  local items, backpacks, price = GameNpcTrade.getBuyAmount(selectedItem, quantity)
  local tooltipText             = string.format('Name: %s', selectedItem.name)
  tooltipText                   = tooltipText .. '\n\n' .. 'Price' .. ': ' .. GameNpcTrade.formatCurrency(selectedItem.price) .. GameNpcTrade.formatTrust(selectedItem) .. GameNpcTrade.formatTown(selectedItem)
  tooltipText                   = tooltipText .. (tradeType == BUY and '\n' .. 'Weight' .. ': ' .. string.format('%.2f', selectedItem.weight) .. ' ' .. WEIGHT_UNIT or '')
  tooltipText                   = tooltipText .. '\n\n' .. 'Count' .. ': ' .. quantity
  tooltipText                   = tooltipText .. '\n' .. 'Total price' .. ': ' .. GameNpcTrade.formatCurrency(price) .. GameNpcTrade.formatTrust(selectedItem) .. GameNpcTrade.formatTown(selectedItem)
  tooltipText                   = tooltipText .. (tradeType == BUY and '\n' .. 'Total weight' .. ': ' .. string.format('%.2f', selectedItem.weight * quantity) .. ' ' .. WEIGHT_UNIT or '')

  tradeButton:setTooltip(tooltipText, TooltipType.textBlock)
end

function GameNpcTrade.checkSellAllTooltip()
  sellAllButton:setEnabled(true)

  local total = 0
  local info = ''
  local first = true

  for key, _ in pairs(playerItems) do
    local item = GameNpcTrade.getTradeItemData(key, SELL)
    if item then
      local items, price = GameNpcTrade.getSellAmount(item)
      if items > 0 then
        info = string.format('%s%s* %dx %s: %d %s', info, (not first and '\n' or ''), items, item.name, price, tr(CURRENCY))
        total = total + price

        if first then
          first = false
        end
      end
    end
  end
  if info ~= '' then
    info = string.format('%s\n\nTotal price: %d %s', info, total, tr(CURRENCY))
    sellAllButton:setTooltip(info, TooltipType.textBlock)
  else
    sellAllButton:setEnabled(false)
    sellAllButton:removeTooltip()
  end
end

function GameNpcTrade.formatCurrency(amount)
  if CURRENCY_DECIMAL then
    return string.format('%.02f', amount/100.0) .. ' ' .. (CURRENCY_ISVIP and CURRENCY_VIP or CURRENCY)
  else
    return amount .. ' ' .. (CURRENCY_ISVIP and CURRENCY_VIP or CURRENCY)
  end
end

function GameNpcTrade.formatTrust(item)
  return GameNpcTrade.getCurrentTradeType() == SELL and item.addTrustOnSell and ' + trust' or ''
end

function GameNpcTrade.formatTown(item)
  return GameNpcTrade.getCurrentTradeType() == SELL and item.addTrustOnSell and getTownStr() or ''
end

function GameNpcTrade.getMaxAmount()
  if GameNpcTrade.getCurrentTradeType() == SELL and g_game.getFeature(GameDoubleShopSellAmount) then
    return 10000
  end
  return 100
end

function GameNpcTrade.sellAll()
  for itemid,_ in pairs(playerItems) do
    local item = GameNpcTrade.getTradeItemData(itemid, SELL)
    if item then
      local quantity = GameNpcTrade.getSellQuantity(item.ptr)
      if quantity > 0 then
        g_game.sellItem(item.ptr, item.maskptr, item.maskOutfitType, item.maskOutfitMount, quantity, ignoreEquipped:isChecked())
        addEvent(function()
          if g_tooltip then
            Tooltip.hide()
          end
        end)
      end
    end
  end
end

function GameNpcTrade.getBuyAmount(item, count) -- (item[, count])
  local items = 0
  local buyWithBackpacks = buyWithBackpack:isChecked()

  if item.ptr:isStackable() or not buyWithBackpacks then
    local _playerMoney = math.max(0, playerMoney - (buyWithBackpacks and backpackPrice or 0))
    items = math.floor(_playerMoney / item.price)
  else

    -- Non stackable and buyWithBackpack
    local _playerMoney = playerMoney
    local minimumCost  = item.price + backpackPrice
    -- Should be possible to buy at least 1 item + 1 backpack and have bought less than 100 items to next loop
    while _playerMoney >= minimumCost and items < GameNpcTrade.getMaxAmount() do -- Buying each backpack of items until 100 items (it will loop until 5 times, since 100 is the limit)
      local amount = math.min(math.floor(_playerMoney / item.price), backpackSize)
      _playerMoney = _playerMoney - backpackPrice - amount * item.price
      items = items + amount
    end
  end

  local capacityMaxCount = not ignoreCapacity:isChecked() and math.floor(playerFreeCapacity / item.weight) or 65535
  items = math.max(0, math.min(count or items, GameNpcTrade.getMaxAmount(), capacityMaxCount))
  local backpacks = buyWithBackpacks and (not item.ptr:isStackable() and math.ceil(items / backpackSize) or items >= 1 and 1 or 0) or 0
  local price     = items * item.price + (not CURRENCY_ISVIP and backpacks * backpackPrice or 0)

  if count and count > items then
    return 0, 0, 0
  end
  return items, backpacks, price
end

function GameNpcTrade.getSellAmount(item, count) -- (item[, count])
  local items = GameNpcTrade.getSellQuantity(item.ptr)
  local buyWithBackpacks = buyWithBackpack:isChecked()
  items       = math.max(0, math.min(count or items, GameNpcTrade.getMaxAmount()))
  local price = items * item.price

  if count and count > items then
    return 0, 0, 0
  end
  return items, price
end
