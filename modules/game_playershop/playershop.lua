g_locales.loadLocales(resolvepath(''))

_G.GamePlayerShop = { }



-- See achievements on server

GpsStr     = 'gps'
WeightUnit = loc'${CorelibInfoOz}'

BackpackSize   = 20
BackpackPrice  = 20
BackpackWeight = 18
ItemMaxAmount  = 100

ConstSlotFirst = 1 -- Server CONST_SLOT_FIRST
ConstSlotLast  = 10 -- Server CONST_SLOT_LAST

IgnoreInventory = true -- Old checkbox which now we use as a flag constant to ignore inventory when selling items



TradeType = {
  Buy  = 1,
  Sell = 2,
}

-- Error

TradeNoError               = 0
TradeUnknownError          = 1
TradeErrorNoEnoughMoney    = 2
TradeErrorNoEnoughCapacity = 3
TradeErrorItemNotFound     = 5
TradeErrorInventoryItem    = 6

TradeErrorStr = {
  [TradeNoError]               = '',
  [TradeUnknownError]          = loc'${GamePlayerShopUnknownError}',
  [TradeErrorNoEnoughMoney]    = loc'${GamePlayerShopErrorNoEnoughMoney}',
  [TradeErrorNoEnoughCapacity] = loc'${GamePlayerShopErrorNoEnoughCapacity}',
  [TradeErrorItemNotFound]     = loc'${GamePlayerShopErrorItemNotFound}',
  [TradeErrorInventoryItem]    = loc'${GamePlayerShopErrorInventoryItem}',
}

-- Widget

shopWindow              = nil
itemsPanelListScrollBar = nil
itemsPanel              = nil
radioTabs               = nil
radioItems              = nil
searchText              = nil
setupPanel              = nil
quantityScroll          = nil
nameLabel               = nil
priceLabel              = nil
moneyLabel              = nil
weightDesc              = nil
weightLabel             = nil
capacityDesc            = nil
capacityLabel           = nil
tradeButton             = nil
buyTab                  = nil
sellTab                 = nil
bankTrade               = nil
buyWithBackpack         = nil
ignoreCapacity          = nil
showAllItems            = nil
sellAllButton           = nil



initialized = false

cancelNextPopupRelease = nil

playerMoney     = 0
playerBankMoney = 0

tradeItems   = { }
playerItems  = { }
selectedItem = nil

temporaryItemBox = nil

function GamePlayerShop.onHoverChange(widget, hovered)
  if hovered then
    widget:setColor('#FFFFFF')
  else
    widget:setColor('#AAAAAA')
  end
end

function GamePlayerShop.init()
  -- Alias
  GamePlayerShop.m = modules.game_playershop

  shopWindow = g_ui.displayUI('playershop')
  shopWindow:setVisible(false)
  shopWindow.onHoverChange = function(self, hovered)

    GamePlayerShop.onHoverChange(self, hovered)

  local item = g_ui.getDraggingWidget()
    if item and item:getStyleName() == "Item" then
      if hovered and not temporaryItemBox then
        print("teste ".. tostring(hovered))
        print_r(item:getStyleName())
        local index = GamePlayerShop.getIndexByPos(mousePos)
        temporaryItemBox = GamePlayerShop.createItemBox({id = item:getItemId(),subType = item:getItemSubType(), temp = true})
        itemsPanel:moveChildToIndex(temporaryItemBox, index)
      end
    end
  end

  itemsPanelListScrollBar = shopWindow.itemsArea.itemsPanelListScrollBar

  itemsPanel = shopWindow.itemsArea.itemsPanel
  searchText = shopWindow.buyOptions.searchText

  setupPanel    = shopWindow.setupPanel
  tradeButton   = shopWindow.tradeButton
  sellAllButton = shopWindow.sellAllButton

  quantityScroll = setupPanel.quantityScroll
  nameLabel      = setupPanel.name
  priceLabel     = setupPanel.price
  moneyLabel     = setupPanel.money
  weightDesc     = setupPanel.weightDesc
  weightLabel    = setupPanel.weight
  capacityDesc   = setupPanel.capacityDesc
  capacityLabel  = setupPanel.capacity

  bankTrade       = shopWindow.buyOptions.bankTrade
  buyWithBackpack = shopWindow.buyOptions.buyWithBackpack
  ignoreCapacity  = shopWindow.buyOptions.ignoreCapacity
  showAllItems    = shopWindow.buyOptions.showAllItems

  buyTab  = shopWindow.buyTab
  sellTab = shopWindow.sellTab

  radioTabs = UIRadioGroup.create()
  radioTabs:addWidget(buyTab)
  radioTabs:addWidget(sellTab)
  radioTabs:selectWidget(buyTab)
  radioTabs.onSelectionChange = GamePlayerShop.onTradeTypeChange

  bankTrade:setChecked(true) -- Bank trade as default

  cancelNextPopupRelease = false

  connect(g_game, {
    onGameEnd       = GamePlayerShop.hide,
    onPlayerGoods   = GamePlayerShop.onPlayerGoods
  })

  connect(LocalPlayer, {
    onFreeCapacityChange = GamePlayerShop.onFreeCapacityChange,
    onInventoryChange    = GamePlayerShop.onInventoryChange
  })

  ProtocolGame.registerOpcode(ServerOpcodes.ServerOpcodeOpenShop, GamePlayerShop.openShop)
  ProtocolGame.registerOpcode(ServerOpcodes.ServerOpcodeCloseShop, GamePlayerShop.closeShop)
  initialized = true
end

function GamePlayerShop.terminate()
  initialized = false

  shopWindow:destroy()

  ProtocolGame.unregisterOpcode(ServerOpcodes.ServerOpcodeOpenShop)
  ProtocolGame.unregisterOpcode(ServerOpcodes.ServerOpcodeCloseShop)

  disconnect(g_game, {
    onGameEnd       = GamePlayerShop.hide,
    onPlayerGoods   = GamePlayerShop.onPlayerGoods
  })

  disconnect(LocalPlayer, {
    onFreeCapacityChange = GamePlayerShop.refreshPlayerGoods,
    onInventoryChange    = GamePlayerShop.refreshPlayerGoods,
  })

  _G.GamePlayerShop = nil
end



-- General

function GamePlayerShop.onDrop(widget, droppedWidget, mousePos)
  if widget == itemsPanel and droppedWidget:getClassName() == 'UIItem' then
    print("dropped")
    LocalPlayer:sendShopAddItem(droppedWidget:getItem())
  end
end

function GamePlayerShop.sendShopAddItem(item)
  if not item or not g_game.isOnline() then
    return
  end

  g_game.addShopItem(item)
end

function GamePlayerShop.show()
  if not g_game.isOnline() then
    return
  end

  if #tradeItems > 0 then
    radioTabs:selectWidget(buyTab)
  else
    radioTabs:selectWidget(sellTab)
  end

  itemsPanelListScrollBar:setValue(0)

  shopWindow:show()
  shopWindow:raise()
  shopWindow:focus()
end

function GamePlayerShop.hide()
  shopWindow:hide()
end

function GamePlayerShop.getCurrentTradeType()
  if tradeButton:getText() == loc'${GamePlayerShopTabSell}' then
    return TradeType.Sell
  end

  return TradeType.Buy
end

function GamePlayerShop.getCurrentMoney(item)
  return bankTrade:isChecked() and playerBankMoney or playerMoney
end

function GamePlayerShop.formattedGoldPieces(amount)
  return f('%s %s', loc(amount), GpsStr)
end

function GamePlayerShop.formattedPrice(item) -- (item) or (price)
  if type(item) == 'table' then
    return f('%s %s', loc(item.price), GpsStr)
  end

  return f('%s %s', item, GpsStr)
end





-- Trade

function GamePlayerShop.getTradeItemData(id, tradeType)
  if table.empty(tradeItems[tradeType]) then
    return nil
  end

  -- Find in chosen TradeType
  if tradeType then
    for _, item in pairs(tradeItems[tradeType]) do
      if item.ptr and item.ptr:getId() == id then
        return item
      end
    end
    return nil
  end

  -- Find in all trade types
  for _, items in pairs(tradeItems) do
    for _, item in pairs(items) do
      if item.ptr and item.ptr:getId() == id then
        return item
      end
    end
  end

  return nil
end

function GamePlayerShop.canTradeItem(item)
  local localPlayer = g_game.getLocalPlayer()
  local tradeType   = GamePlayerShop.getCurrentTradeType()

  if tradeType == TradeType.Buy then
    local _, _, unitPrice = GamePlayerShop.getBuyAmount(item, 1)

    if unitPrice < 0 then
      return TradeUnknownError
    elseif GamePlayerShop.getCurrentMoney(item) < unitPrice then
      return TradeErrorNoEnoughMoney
    elseif not ignoreCapacity:isChecked() and localPlayer:getFreeCapacity() < item.weight then
      return TradeErrorNoEnoughCapacity
    end

  elseif tradeType == TradeType.Sell then
    local itemsAmount, unitPrice = GamePlayerShop.getSellAmount(item)

    if unitPrice < 0 then
      return TradeUnknownError
    elseif itemsAmount < 1 then
      if IgnoreInventory then
        local inventorySellQuantity = GamePlayerShop.getInventorySellQuantity(item.ptr)
        if inventorySellQuantity > 0 then
          return TradeErrorInventoryItem
        end
      end
      return TradeErrorItemNotFound
    end
  end

  return TradeNoError
end

function GamePlayerShop.getIndexByPos(mousePos)
  local itemBoxes = radioItems.widgets
  local index = 1
  for i, w in ipairs(itemBoxes) do
    if mousePos.x <= w:getX() + math.floor(w:getWidth() / 2) then
      index = i
      break
    end
    index = i + 1
  end
  return index
end

function GamePlayerShop.refreshPlayerGoods()
  if not initialized or not shopWindow:isVisible() then
    return
  end

  local localPlayer       = g_game.getLocalPlayer()
  local currentTradeType  = GamePlayerShop.getCurrentTradeType()
  local searchFilter      = searchText:getText():lower()
  local isBankTrade       = bankTrade:isChecked()
  local foundSelectedItem = false

  -- Refresh player goods base values
  moneyLabel:setText(f('%s (%s)', GamePlayerShop.formattedGoldPieces(isBankTrade and playerBankMoney or playerMoney), isBankTrade and loc'${GamePlayerShopGoodsFromBank}' or loc'${GamePlayerShopGoodsHoldingMoney}'))
  capacityLabel:setText(f('%s %s', loc(localPlayer:getFreeCapacity()), WeightUnit))

  -- Update tooltip

  GamePlayerShop.updateTradeButtonTooltip()
  GamePlayerShop.updateSellAllButtonTooltip()

  -- Refresh store items according to player goods

  -- For each item box
  for i = 1, itemsPanel:getChildCount() do
    local shopItemBox  = itemsPanel:getChildByIndex(i)
    local itemBox     = shopItemBox.itemBox -- Clickable item checkbox
    local boxOutfit   = itemBox.outfit
    local tradeItem   = itemBox.tradeItem
    local canTradeRet = GamePlayerShop.canTradeItem(tradeItem)
    local canTrade    = canTradeRet == TradeNoError

    -- Enable item box according to canTrade
    itemBox:setOn(canTrade)
    itemBox:setEnabled(canTrade)
    boxOutfit:setOn(canTrade)

    -- Set item box visibility according to search condition and show all items condition
    local searchCondition       = searchFilter == '' or tradeItem.name:lower():find(searchFilter)
    local showAllItemsCondition = currentTradeType == TradeType.Buy or showAllItems:isChecked() or currentTradeType == TradeType.Sell and not showAllItems:isChecked() and canTrade
    shopItemBox:setVisible(searchCondition and showAllItemsCondition)

    -- Update info button tooltip
    local infoWidget = shopItemBox.infoButton
    infoWidget:setTooltip(f('%s%s', infoWidget.tooltipText, canTradeRet ~= TradeNoError and TradeErrorStr[canTradeRet] and f('\n\n%s', TradeErrorStr[canTradeRet]) or ''), TooltipType.textBlock)

    if not foundSelectedItem and selectedItem == tradeItem and shopItemBox:isVisible() and itemBox:isEnabled() then
      foundSelectedItem = true
    end
  end

  -- If selected item is not found in the search condition, clear its selection
  if not foundSelectedItem then
    GamePlayerShop.clearSelectedItem()
  end

  -- If there is still a selected item, refresh it
  if selectedItem then
    GamePlayerShop.refreshSelectedItem(selectedItem)
  end
end

do
  local function onItemMouseRelease(self, mousePosition, mouseButton)
    if cancelNextPopupRelease then
      cancelNextPopupRelease = false
      return false
    end

    local function onLook()
      return g_game.inspectNpcTrade(self:getItem())
    end

    -- Look
    if g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton or
       g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton or
       mouseButton == MouseLeftButton and g_keyboard.isShiftPressed()
    then
      cancelNextPopupRelease = true
      onLook()

      return true

    -- Context menu
    elseif mouseButton == MouseRightButton then
      local menu = g_ui.createWidget('PopupMenu')

      menu:setGameMenu(true)
      menu:addOption(loc'${GamePlayerShopContextMenuLook}', onLook, '(Shift)')
      menu:display(mousePosition)

      return true
    end

    return false
  end

  function GamePlayerShop.createItemBox(item)
    print_r(item)
    local shopItemBox = g_ui.createWidget('ShopItemBox', itemsPanel)
    local itemBox    = shopItemBox.itemBox -- Clickable item checkbox
    local boxOutfit  = itemBox.outfit
    local boxItem    = itemBox.item

    if item.temp then
      shopItemBox:setOpacity(0.5)
            -- Update item
      boxItem:setItemId(item.id)
      boxItem:setItemSubType(item.subType or 0)
      boxItem.onMouseRelease = onItemMouseRelease
    else
    -- Attach trade item
    itemBox.tradeItem = item
    itemBox:setText(f('%s\n%s\n%.2f %s', item.name, GamePlayerShop.formattedPrice(item), item.weight, WeightUnit))

      local infoWidget = shopItemBox.infoButton -- Update info widget text
      infoWidget.tooltipText = f(loc'%s\n\n${CorelibInfoName}: %s\n${GamePlayerShopInfoPrice}: %s\n${GamePlayerShopInfoWeight}: %.2f %s', item.description, item.name, GamePlayerShop.formattedPrice(item), item.weight, WeightUnit)
      infoWidget:setTooltip(infoWidget.tooltipText, TooltipType.textBlock)
    end

      -- Update item
      boxItem:setItemId(item.id)
      boxItem:setItemSubType(item.subType or 0)
      boxItem.onMouseRelease = onItemMouseRelease


    -- Add item box to items list
    radioItems:addWidget(itemBox)
    return itemBox
  end

  function GamePlayerShop.refreshTradeItems()
    local layout                = itemsPanel:getLayout()
    local localPlayer           = g_game.getLocalPlayer()
    local tradeType             = GamePlayerShop.getCurrentTradeType()

    -- Disable layout updates
    layout:disableUpdates()

    -- Clear selected item
    GamePlayerShop.clearSelectedItem()

    -- Clear items of panel
    itemsPanel:destroyChildren()
    if radioItems then
      radioItems:destroy()
    end
    radioItems = UIRadioGroup.create()

    -- Clear other stuff
    searchText:clearText()
    setupPanel:disable()

    -- For each available item
    for _, tradeItem in pairs(tradeItems) do
      -- Create item box
      GamePlayerShop.createItemBox(tradeItem)
    end

    -- Enable layout updates
    layout:enableUpdates()

    -- Force layout update
    layout:update()
  end
end

function GamePlayerShop.closeShop()
  -- Hide window
  GamePlayerShop.hide()
end



-- Buy

function GamePlayerShop.getBuyAmount(item, amount) -- (item[, amount])
  local localPlayer      = g_game.getLocalPlayer()
  local buyWithBackpacks = buyWithBackpack:isChecked()
  local backpackPrice    = buyWithBackpacks and BackpackPrice or 0
  local itemsAmount      = 0

  if not amount then
    local money = GamePlayerShop.getCurrentMoney(item)

    -- Item is stackable or 'buy with backpacks' checkbox is disabled
    if item.ptr:isStackable() or not buyWithBackpacks then
      itemsAmount = math.floor(math.max(0, money - backpackPrice) / item.price)

    -- Item is non-stackable and 'buy with backpacks' checkbox is enabled
    else
      -- Check item amount according to player money, up to ItemMaxAmount
      local minimumCost = item.price + backpackPrice
      while money >= minimumCost and itemsAmount < ItemMaxAmount do
        -- Buying each backpack of items until 100 items (it will loop until 5 times, since 5 * BackpackSize = ItemMaxAmount)
        local amount = math.min(math.floor(money / item.price), BackpackSize)
        local price  = amount * item.price + BackpackPrice

        if money < price then
          break
        end

        money       = money - price
        itemsAmount = itemsAmount + amount
      end
    end
  end

  -- Fit itemsAmount according to capItemAmount and ItemMaxAmount
  local capItemAmount = not ignoreCapacity:isChecked() and math.floor(localPlayer:getFreeCapacity() / item.weight) or ItemMaxAmount
  itemsAmount         = math.max(0, math.min(amount or itemsAmount, capItemAmount, ItemMaxAmount))

  local backpacks = buyWithBackpacks and (not item.ptr:isStackable() and math.ceil(itemsAmount / BackpackSize) or itemsAmount >= 1 and 1 or 0) or 0
  local price     = itemsAmount * item.price + backpacks * backpackPrice

  if amount and amount > itemsAmount then
    return 0, 0, 0
  end

  return itemsAmount, backpacks, price
end



-- Sell

function GamePlayerShop.getInventorySellQuantity(item)
  if not item or not playerItems[item:getId()] then
    return 0
  end

  local amount      = 0
  local localPlayer = g_game.getLocalPlayer()

  for slot = ConstSlotFirst, ConstSlotLast do
    local inventoryItem = localPlayer:getInventoryItem(slot)

    if inventoryItem and inventoryItem:getId() == item:getId() then
      amount = amount + inventoryItem:getCount()
    end
  end

  return amount
end

function GamePlayerShop.getSellQuantity(item)
  if not item or not playerItems[item:getId()] then
    return 0
  end

  return playerItems[item:getId()] - (IgnoreInventory and GamePlayerShop.getInventorySellQuantity(item) or 0)
end

function GamePlayerShop.getSellAmount(item, amount) -- (item[, amount])
  local itemsAmount = math.max(0, math.min(amount or GamePlayerShop.getSellQuantity(item.ptr), ItemMaxAmount))

  if amount and amount > itemsAmount then
    return 0, 0
  end

  return itemsAmount, itemsAmount * item.price
end

function GamePlayerShop.sellAll()
  -- For all player items
  for itemId in pairs(playerItems) do
    -- Get item data
    local item = GamePlayerShop.getTradeItemData(itemId, TradeType.Sell)
    if item then
      -- Get sell quantity
      local quantity = GamePlayerShop.getSellQuantity(item.ptr)
      if quantity > 0 then

        -- Sell item in specified quantity
        g_game.sellItem(item.ptr, item.maskptr, item.maskOutfitType, item.maskOutfitMount, quantity, bankTrade:isChecked(), IgnoreInventory)
      end
    end
  end

  if g_tooltip then
    Tooltip.hide()
  end
end



-- Selected item

function GamePlayerShop.clearSelectedItem()
  nameLabel:clearText()
  priceLabel:clearText()
  weightLabel:clearText()
  tradeButton:disable()
  quantityScroll:setMinimum(0)
  quantityScroll:setMaximum(0)

  if selectedItem then
    radioItems:selectWidget(nil)
    selectedItem = nil
  end
end

function GamePlayerShop.refreshSelectedItem()
  if not selectedItem then
    return
  end

  local tradeType        = GamePlayerShop.getCurrentTradeType()
  local quantity         = quantityScroll:getValue()
  local buyWithBackpacks = buyWithBackpack:isChecked()
  local backpackWeight   = buyWithBackpacks and BackpackWeight or 0

  local itemsAmount, backpacks, totalPrice, _
  if tradeType == TradeType.Buy then
    itemsAmount              = GamePlayerShop.getBuyAmount(selectedItem)
    _, backpacks, totalPrice = GamePlayerShop.getBuyAmount(selectedItem, quantity)
  else
    itemsAmount   = GamePlayerShop.getSellAmount(selectedItem)
    _, totalPrice = GamePlayerShop.getSellAmount(selectedItem, quantity)
  end

  nameLabel:setText(selectedItem.name)

  priceLabel:setText(f('%s', GamePlayerShop.formattedPrice(totalPrice)))

  weightLabel:setText(tradeType == TradeType.Buy and f('%.2f %s', selectedItem.weight * quantity + backpackWeight * backpacks, WeightUnit) or '')
  quantityScroll:setMinimum(itemsAmount > 0 and 1 or 0)
  quantityScroll:setMaximum(itemsAmount)

  setupPanel:enable()

  GamePlayerShop.updateTradeButtonTooltip()
end



-- Tooltip

function GamePlayerShop.updateTradeButtonTooltip()
  if not selectedItem then
    tradeButton:removeTooltip()
    return
  end

  local tradeType = GamePlayerShop.getCurrentTradeType()
  local quantity  = quantityScroll:getValue()

  local _, backpacks, totalPrice
  if tradeType == TradeType.Buy then
    _, backpacks, totalPrice = GamePlayerShop.getBuyAmount(selectedItem, quantity)
  else
    _, totalPrice = GamePlayerShop.getSellAmount(selectedItem, quantity)
  end

  -- Name
  local text = f(loc'${CorelibInfoName}: %s', selectedItem.name)

  -- Price
  text = f(loc'%s\n\n${GamePlayerShopInfoPrice}: %s', text, GamePlayerShop.formattedPrice(selectedItem))

  -- Weight
  if tradeType == TradeType.Buy then
    text = f(loc'%s\n${GamePlayerShopInfoWeight}: %.2f %s', text, selectedItem.weight, WeightUnit)
  end


  -- Count
  text = f(loc'%s\n\n${GamePlayerShopInfoCount}: %d', text, quantity)

  -- Total price
  text = f(loc'%s\n${GamePlayerShopInfoTotalPrice}: %s', text, GamePlayerShop.formattedPrice(totalPrice))

  if tradeType == TradeType.Buy then
    -- Total weight
    local buyWithBackpacks = buyWithBackpack:isChecked()
    local backpackWeight   = buyWithBackpacks and BackpackWeight or 0
    text = f(loc'%s\n${GamePlayerShopInfoTotalWeight}: %.2f %s', text, selectedItem.weight * quantity + backpackWeight * backpacks, WeightUnit)

    -- Backpack note
    text = f('%s%s', text, buyWithBackpack:isChecked() and f(loc'\n${GamePlayerShopInfoBpIncluded}', backpacks) or '')
  end

  tradeButton:setTooltip(text, TooltipType.textBlock)
end

function GamePlayerShop.updateSellAllButtonTooltip()
  local text           = ''
  local first          = true
  local finalPriceGps  = 0

  -- For all player items
  for itemId in pairs(playerItems) do
    -- Get item data
    local item = GamePlayerShop.getTradeItemData(itemId, TradeType.Sell)
    if item then
      -- Get sell amount and price
      local itemsAmount = GamePlayerShop.getSellAmount(item)
      if itemsAmount > 0 then
        local _, totalPrice = GamePlayerShop.getSellAmount(item, itemsAmount)

        -- Add item amount and price to text
        text  = f('%s%s* %dx %s: %s %s', text, (first and '' or '\n'), itemsAmount, item.name, loc(totalPrice), GpsStr)
        first = false
        finalPriceGps = finalPriceGps + totalPrice
      end
    end
  end

  -- Has content
  if text ~= '' then
    sellAllButton:setEnabled(true)

    do
      local finalPrices = { }
      if finalPriceGps > 0 then
        finalPrices[#finalPrices + 1] = f('%s %s', finalPriceGps, GpsStr)
      end
      text = f(loc'%s\n\n${GamePlayerShopInfoTotalPrice}: %s', text, table.list(finalPrices))
    end

    sellAllButton:setTooltip(text, TooltipType.textBlock)

  -- Has no content
  else
    sellAllButton:setEnabled(false)
    sellAllButton:removeTooltip()
  end
end



-- Trigger

function GamePlayerShop.onTradeTypeChange(radioTabs, selected, deselected)
  -- Update trade type tab
  tradeButton:setText(selected:getText())
  selected:setOn(true)
  deselected:setOn(false)

  -- Get updated trade type
  local currentTradeType = GamePlayerShop.getCurrentTradeType()

  buyWithBackpack:setVisible(currentTradeType == TradeType.Buy)
  ignoreCapacity:setVisible(currentTradeType == TradeType.Buy)
  showAllItems:setVisible(currentTradeType == TradeType.Sell)
  sellAllButton:setVisible(currentTradeType == TradeType.Sell)

  GamePlayerShop.refreshTradeItems()
  GamePlayerShop.refreshPlayerGoods()

  itemsPanelListScrollBar:setValue(0)
end

function GamePlayerShop.onTradeClick()
  if not selectedItem then
    return
  end

  local currentTradeType = GamePlayerShop.getCurrentTradeType()

  if currentTradeType == TradeType.Buy then
    g_game.buyItem(selectedItem.ptr, selectedItem.maskptr, selectedItem.maskOutfitType, selectedItem.maskOutfitMount, quantityScroll:getValue(), bankTrade:isChecked(), ignoreCapacity:isChecked(), buyWithBackpack:isChecked())
  elseif currentTradeType == TradeType.Sell then
    g_game.sellItem(selectedItem.ptr, selectedItem.maskptr, selectedItem.maskOutfitType, selectedItem.maskOutfitMount, quantityScroll:getValue(), bankTrade:isChecked(), IgnoreInventory)
  end
end

function GamePlayerShop.onItemBoxChecked(widget)
  if not widget:isChecked() then
    return
  end

  selectedItem = widget.tradeItem

  GamePlayerShop.refreshSelectedItem()
  tradeButton:enable()

  quantityScroll:setValue(quantityScroll:getMinimum())
end



-- Callback

function GamePlayerShop.onClose()
  GamePlayerShop.hide()
end

function GamePlayerShop.onPlayerGoods(money, bankMoney, items)
  playerItems = { }

  playerMoney     = money
  playerBankMoney = bankMoney

  for _, item in ipairs(items) do
    local id        = item[1]:getId()
    playerItems[id] = (playerItems[id] or 0) + item[2]
  end

  GamePlayerShop.refreshPlayerGoods()
end


local config = {
  tradeItems = {},
  isOwner    = false,
  shopName   = "",
}

-- Protocol Receive
function GamePlayerShop.openShop(protocol, msg)
  config.tradeItems = {}
  config.isOwner = msg:getU8() ~= 0
  config.shopName = msg:getString()

  local itemCount = msg:getU16()
  for i = 1, itemCount do
    tradeItems[i] = {
      clientId = msg:getU16(),
      subType = msg:getU8(),
      name = msg:getString(),
      description = msg:getString(),
      weight = msg:getU32() / 100,
      class = msg:getU8(),
      tier = msg:getU8(),
      durability = msg:getU32(),
      price = msg:getU32(),
    }
  end
  print_r(itemCount)
  print_r(tradeItems)

  GamePlayerShop.show()
  if isOwner then
    connect(shopWindow, { onDrop = GamePlayerShop.onDropItem })
  end
end

-- Protocol Send

function GamePlayerShop.sendAddShopItem(pos, index)
  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeAddShopItem)
  msg:addPosition(pos)
  msg:addU8(index)
  g_game.getProtocolGame():send(msg)
end

function GamePlayerShop.sendRemoveShopItem(index)
  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeRemoveShopItem)
  msg:addU8(index)
  g_game.getProtocolGame():send(msg)
end

function GamePlayerShop.sendConfigShopItem(index, price, isSell)
  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeConfigShopItem)
  msg:addU8(index)
  msg:addU32(price)
  msg:addU8(isSell and 1 or 0)
  g_game.getProtocolGame():send(msg)
end

function GamePlayerShop.sendMoveShopItem(fromIndex, toIndex)
  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeMoveShopItem)
  msg:addU8(fromIndex)
  msg:addU8(toIndex)
  g_game.getProtocolGame():send(msg)
end

function GamePlayerShop.sendCloseShop()
  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeCloseShop)
  g_game.getProtocolGame():send(msg)
end