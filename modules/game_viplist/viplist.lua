g_locales.loadLocales(resolvepath(''))

_G.GameVipList = { }



local GameVipListActionKey = 'Ctrl+F'



vipWindow = nil
vipTopMenuButton = nil
addVipWindow = nil
editVipWindow = nil
addGroupWindow = nil
contentsPanel = nil
vipInfo = { }
vipGroups = { }
maxVipGroups = 0
GameVipList.showGrouped = true



function GameVipList.init()
  -- Alias
  GameVipList.m = modules.game_viplist

  connect(g_game, {
    onGameStart      = GameVipList.online,
    onGameEnd        = GameVipList.offline,
    onAddVip         = GameVipList.onAddVip,
    onVipStateChange = GameVipList.onVipStateChange,
    onVipGroupChange = GameVipList.onVipGroupChange
  })

  g_keyboard.bindKeyDown(GameVipListActionKey, GameVipList.toggle)

  vipWindow = g_ui.loadUI('viplist')
  vipTopMenuButton = ClientTopMenu.addRightGameToggleButton('vipTopMenuButton', { loct = '${GameVipListWindowTitle} (${GameVipListActionKey})', locpar = { GameVipListActionKey = GameVipListActionKey } }, '/images/ui/top_menu/viplist', GameVipList.toggle)
  contentsPanel = vipWindow:getChildById('contentsPanel')

  vipWindow.topMenuButton = vipTopMenuButton
  contentsPanel.onMousePress = GameVipList.onVipListMousePress

  if not g_game.getFeature(GameAdditionalVipInfo) then
    GameVipList.loadVipInfo()
  end

  local settings = g_settings.getNode('VipList')
  if settings then
    if settings['showGrouped'] ~= nil then
      GameVipList.showGrouped = settings['showGrouped']
    end
  end

  if g_game.isOnline() then
    GameVipList.online()
  end
end

function GameVipList.terminate()
  g_keyboard.unbindKeyDown(GameVipListActionKey)
  disconnect(g_game, {
    onGameStart      = GameVipList.online,
    onGameEnd        = GameVipList.offline,
    onAddVip         = GameVipList.onAddVip,
    onVipStateChange = GameVipList.onVipStateChange,
    onVipGroupChange = GameVipList.onVipGroupChange
  })

  if not g_game.getFeature(GameAdditionalVipInfo) then
    GameVipList.saveVipInfo()
  end

  if addVipWindow then
    addVipWindow:destroy()
  end

  if editVipWindow then
    editVipWindow:destroy()
  end

  GameVipList.destroyAddGroupWindow()

  vipWindow:destroy()
  vipTopMenuButton:destroy()
  vipWindow = nil
  vipTopMenuButton = nil
  addGroupWindow = nil

  _G.GameVipList = nil
end

function GameVipList.loadVipInfo()
  local settings = g_settings.getNode('VipList')
  if not settings then
    vipInfo = { }
    return
  end
  vipInfo = settings['VipInfo'] or { }
end

function GameVipList.saveVipInfo()
  settings = { }
  settings['VipInfo'] = vipInfo
  g_settings.mergeNode('VipList', settings)
end

function GameVipList.clear()
  contentsPanel:destroyChildren()
end

function GameVipList.online()
  vipWindow:setup(vipTopMenuButton)

  GameVipList.clear()
  if g_game.getFeature(GameVipGroups) and GameVipList.showGrouped then
    GameVipList.showGroups()
    return
  end
  for id,vip in pairs(g_game.getVips()) do
    GameVipList.onAddVip(id, unpack(vip))
  end
end

function GameVipList.offline()
  GameVipList.clear()
  vipGroups = { }
  maxVipGroups = 0
end

function GameVipList.toggle()
  GameInterface.toggleMiniWindow(vipWindow)
end

function GameVipList.createAddWindow()
  if not addVipWindow then
    addVipWindow = g_ui.displayUI('addvip')
  end
end

function GameVipList.createEditWindow(widget)
  if editVipWindow then
    return
  end

  editVipWindow = g_ui.displayUI('editvip')

  local name = widget:getText()
  local id = widget:getId():sub(4)

  if g_game.getFeature(GameVipGroups) then
    editVipWindow:setHeight(220 + (#vipGroups * 18))
    local groupsPanel = editVipWindow:getChildById('groups')
    groupsPanel:destroyChildren()
    for _, group in ipairs(vipGroups) do
      local groupBox = g_ui.createWidget('VipGroupBox', groupsPanel)
      groupBox:setText(group[2])
      groupBox.groupId = group[1]
      groupBox:setChecked(GameVipList.isVipInGroup(tonumber(id), group[1]))
    end
    groupsPanel:setHeight(#vipGroups * 18)
  end

  local okButton = editVipWindow:getChildById('buttonOK')
  local cancelButton = editVipWindow:getChildById('buttonCancel')

  local nameLabel = editVipWindow:getChildById('nameLabel')
  nameLabel:setText(name)

  local descriptionText = editVipWindow:getChildById('descriptionText')
  descriptionText:appendText(widget:getTooltip())

  local notifyCheckBox = editVipWindow:getChildById('checkBoxNotify')
  notifyCheckBox:setChecked(widget.notifyLogin)

  local iconRadioGroup = UIRadioGroup.create()
  for i = VipIconFirst, VipIconLast do
    iconRadioGroup:addWidget(editVipWindow:recursiveGetChildById('icon' .. i))
  end
  iconRadioGroup:selectWidget(editVipWindow:recursiveGetChildById('icon' .. widget.iconId))

  local cancelFunction = function()
    editVipWindow:destroy()
    iconRadioGroup:destroy()
    editVipWindow = nil
  end

  local saveFunction = function()
    if not widget then
      cancelFunction()
      return
    end

    local name = widget:getText()
    local state = widget.vipState
    local description = descriptionText:getText()
    local iconId = tonumber(iconRadioGroup:getSelectedWidget():getId():sub(5))
    local notify = notifyCheckBox:isChecked()
    local groups = {}
    if g_game.getFeature(GameVipGroups) then
      for _, groupBox in ipairs(editVipWindow:getChildById('groups'):getChildren()) do
        if groupBox:isChecked() then
          table.insert(groups, groupBox.groupId)
        end
      end
    end

    if g_game.getFeature(GameAdditionalVipInfo) then
      g_game.editVip(id, description, iconId, notify, groups)
    else
      if notify ~= false or #description > 0 or iconId > 0 then
        vipInfo[name] = {description = description, iconId = iconId, notifyLogin = notify}
      else
        vipInfo[name] = nil
      end
    end

    widget:destroy()
    GameVipList.onAddVip(id, name, state, description, iconId, notify, groups)

    editVipWindow:destroy()
    iconRadioGroup:destroy()
    editVipWindow = nil
  end

  cancelButton.onClick = cancelFunction
  okButton.onClick = saveFunction

  editVipWindow.onEscape = cancelFunction
  editVipWindow.onEnter = saveFunction
end

function GameVipList.destroyAddWindow()
  addVipWindow:destroy()
  addVipWindow = nil
end

function GameVipList.addVip()
  g_game.addVip(addVipWindow:getChildById('name'):getText())
  GameVipList.destroyAddWindow()
end

function GameVipList.removeVip(widgetOrName)
  if not widgetOrName then
    return
  end

  local widget
  if type(widgetOrName) == 'string' then
    local entries = contentsPanel:getChildren()
    for i = 1, #entries do
      if entries[i]:getText():lower() == widgetOrName:lower() then
        widget = entries[i]
        break
      end
    end
    if not widget then
      return
    end
  else
    widget = widgetOrName
  end

  if widget then
    local id = widget:getId():sub(4)
    local name = widget:getText()
    g_game.removeVip(id)
    if vipInfo[name] and g_game.getFeature(GameAdditionalVipInfo) then
      vipInfo[name] = nil
    end

    if g_game.getFeature(GameVipGroups) and GameVipList.showGrouped then
      -- removeVip() updates the local VIP map immediately. Rebuild all groups
      -- so the player disappears from every group and their heights are
      -- recalculated, including the empty-group visibility.
      GameVipList.showGroups()
    else
      widget:destroy()
    end
  end
end

function GameVipList.hideOffline(state)
  settings = { }
  settings['hideOffline'] = state
  g_settings.mergeNode('VipList', settings)

  GameVipList.online()
end

function GameVipList.isHiddingOffline()
  local settings = g_settings.getNode('VipList')
  if not settings then
    return false
  end
  return settings['hideOffline']
end

function GameVipList.getSortedBy()
  local settings = g_settings.getNode('VipList')
  if not settings or not settings['sortedBy'] then
    return 'status'
  end
  return settings['sortedBy']
end

function GameVipList.sortBy(state)
  settings = { }
  settings['sortedBy'] = state
  g_settings.mergeNode('VipList', settings)

  GameVipList.online()
end

function GameVipList.onAddVip(id, name, state, description, iconId, notify, groupIds)
  if g_game.getFeature(GameVipGroups) and GameVipList.showGrouped then
    GameVipList.showGroups()
    return
  end

  local label = contentsPanel:getChildById('vip' .. id)
  if not label then
    label = g_ui.createWidget('VipListLabel')
    label.onMousePress = GameVipList.onVipListLabelMousePress
    label:setId('vip' .. id)
    label:setText(name)
  else
    return
  end

  if not g_game.getFeature(GameAdditionalVipInfo) then
    local tmpVipInfo = vipInfo[name]
    label.iconId = 0
    label.notifyLogin = false
    if tmpVipInfo then
      if tmpVipInfo.iconId then
        label:setImageClip(torect((tmpVipInfo.iconId * 12) .. ' 0 12 12'))
        label.iconId = tmpVipInfo.iconId
      end
      if tmpVipInfo.description then
        label:setTooltip(tmpVipInfo.description)
      end
      label.notifyLogin = tmpVipInfo.notifyLogin or false
    end
  else
    label:setTooltip(description)
    label:setImageClip(torect((iconId * 12) .. ' 0 12 12'))
    label.iconId = iconId
    label.notifyLogin = notify
  end
  label.vipGroups = groupIds or {}

  if state == VipState.Online then
    label:setColor('#00ff00')
  elseif state == VipState.Pending then
    label:setColor('#ffca38')
  else
    label:setColor('#990f0f')
  end

  label.vipState = state

  label:setPhantom(false)

  connect(label, {
    onDoubleClick = function()
      g_game.openPrivateChannel(label:getText())
      return true
    end
  })

  if state == VipState.Offline and GameVipList.isHiddingOffline() then
    label:setVisible(false)
  end

  local nameLower = name:lower()
  local childrenCount = contentsPanel:getChildCount()

  for i = 1, childrenCount do
    local child = contentsPanel:getChildByIndex(i)
    if (state == VipState.Online and child.vipState ~= VipState.Online and GameVipList.getSortedBy() == 'status')
        or (label.iconId > child.iconId and GameVipList.getSortedBy() == 'type') then
      contentsPanel:insertChild(i, label)
      return
    end

    if (((state ~= VipState.Online and child.vipState ~= VipState.Online) or (state == VipState.Online and child.vipState == VipState.Online)) and GameVipList.getSortedBy() == 'status')
        or (label.iconId == child.iconId and GameVipList.getSortedBy() == 'type') or GameVipList.getSortedBy() == 'name' then

      local childText = child:getText():lower()
      local length = math.min(#childText, #nameLower)

      for j=1,length do
        if nameLower:byte(j) < childText:byte(j) then
          contentsPanel:insertChild(i, label)
          return
        elseif nameLower:byte(j) > childText:byte(j) then
          break
        elseif j == #nameLower then -- We are at the end of nameLower, and its shorter than childText, thus insert before
          contentsPanel:insertChild(i, label)
          return
        end
      end
    end
  end

  contentsPanel:insertChild(childrenCount+1, label)
end

function GameVipList.isVipInGroup(vipId, groupId)
  local vip = g_game.getVips()[vipId]
  if not vip or not vip[6] then
    return false
  end
  for _, assignedGroupId in ipairs(vip[6]) do
    if assignedGroupId == groupId then
      return true
    end
  end
  return false
end

function GameVipList.setVipState(widget, state)
  if state == VipState.Online then
    widget:setColor('#00ff00')
  elseif state == VipState.Pending then
    widget:setColor('#ffca38')
  else
    widget:setColor('#990f0f')
  end
end

function GameVipList.showGroups()
  GameVipList.showGrouped = true
  contentsPanel:destroyChildren()

  local groups = { }
  for _, group in ipairs(vipGroups) do
    groups[group[1]] = group
  end
  groups[0] = { 0, loc'${GameVipListGroupNoGroup}', false }

  local playersByGroup = { }
  for id, vip in pairs(g_game.getVips()) do
    local assigned = vip[6] or { }
    if #assigned == 0 then
      playersByGroup[0] = playersByGroup[0] or { }
      table.insert(playersByGroup[0], { id, vip })
    else
      for _, groupId in ipairs(assigned) do
        playersByGroup[groupId] = playersByGroup[groupId] or { }
        table.insert(playersByGroup[groupId], { id, vip })
      end
    end
  end

  local orderedGroups = { }
  for _, group in ipairs(vipGroups) do
    table.insert(orderedGroups, group[1])
  end
  table.insert(orderedGroups, 0)

  for _, groupId in ipairs(orderedGroups) do
    local players = playersByGroup[groupId]
    if groupId ~= 0 or (players and #players > 0) then
      players = players or { }
      local group = groups[groupId]
      local groupWidget = g_ui.createWidget('VipGroupList', contentsPanel)
      groupWidget:setId('group-' .. groupId)
      groupWidget.groupId = groupId
      groupWidget.editable = groupId ~= 0
      groupWidget.onMousePress = GameVipList.onVipListLabelMousePress
      local groupHeader = groupWidget:getChildById('group')
      groupHeader.groupId = groupId
      groupHeader.editable = groupId ~= 0
      groupHeader.onMousePress = GameVipList.onVipListLabelMousePress
      groupHeader:setText(group[2])
      local groupPanel = groupWidget:getChildById('panel')

      table.sort(players, function(a, b) return a[2][1]:lower() < b[2][1]:lower() end)
      local visiblePlayers = 0
      for _, player in ipairs(players) do
        local id, vip = player[1], player[2]
        local label = g_ui.createWidget('VipListLabel', groupPanel)
        label:setId('vip' .. id)
        label:setText(vip[1])
        label:setTooltip(vip[3])
        label:setImageClip(torect((vip[4] or 0) * 12 .. ' 0 12 12'))
        label.iconId = vip[4] or 0
        label.notifyLogin = vip[5]
        label.vipState = vip[2]
        label.groupId = groupId ~= 0 and groupId or nil
        label.groupName = groupId ~= 0 and group[2] or nil
        GameVipList.setVipState(label, vip[2])
        label.onMousePress = GameVipList.onVipListLabelMousePress
        connect(label, { onDoubleClick = function()
          g_game.openPrivateChannel(label:getText())
          return true
        end })
        if vip[2] == VipState.Offline and GameVipList.isHiddingOffline() then
          label:setVisible(false)
        else
          visiblePlayers = visiblePlayers + 1
        end
      end
      groupWidget:setHeight(20 + (visiblePlayers * 16))
      if groupId == 0 and visiblePlayers == 0 then
        groupWidget:setVisible(false)
      end
    end
  end
end

function GameVipList.onVipGroupChange(groups, groupsLeft)
  vipGroups = groups or { }
  maxVipGroups = groupsLeft or 0
  if GameVipList.showGrouped then
    GameVipList.showGroups()
  end
end

function GameVipList.onVipStateChange(id, state)
  if GameVipList.showGrouped then
    local vip = g_game.getVips()[id]
    GameVipList.showGroups()
    if vip and vip[5] and state ~= VipState.Pending then
      if modules.game_textmessage then
        GameTextMessage.displayFailureMessage(state == VipState.Online and f(loc'${GameVipListInfoPlayerLoggedIn}', vip[1]) or f(loc'${GameVipListInfoPlayerLoggedOut}', vip[1]))
      end
    end
    return
  end

  local label = contentsPanel:getChildById('vip' .. id)
  local name = label:getText()
  local description = label:getTooltip()
  local iconId = label.iconId
  local notify = label.notifyLogin
  label:destroy()

  GameVipList.onAddVip(id, name, state, description, iconId, notify)

  if notify and state ~= VipState.Pending then
    if modules.game_textmessage then
      GameTextMessage.displayFailureMessage(state == VipState.Online and f(loc'${GameVipListInfoPlayerLoggedIn}', name) or f(loc'${GameVipListInfoPlayerLoggedOut}', name))
    end
  end
end

function GameVipList.onVipListMousePress(widget, mousePos, mouseButton)
  if mouseButton ~= MouseRightButton then
    return
  end

  local menu = g_ui.createWidget('PopupMenu')
  menu:setGameMenu(true)
  menu:addOption(loc'${GameVipListContextMenuAddVip}', function() GameVipList.createAddWindow() end)

  if g_game.getFeature(GameVipGroups) then
    menu:addOption(loc'${GameVipListContextMenuGroupAdd}', function() GameVipList.createAddGroupWindow() end)
    menu:addOption(GameVipList.showGrouped and loc'${GameVipListContextMenuGroupHide}' or loc'${GameVipListContextMenuGroupShow}', function()
      GameVipList.showGrouped = not GameVipList.showGrouped
      g_settings.mergeNode('VipList', { showGrouped = GameVipList.showGrouped })
      if GameVipList.showGrouped then
        GameVipList.showGroups()
      else
        GameVipList.online()
      end
    end)
  end

  menu:addSeparator()
  if not GameVipList.isHiddingOffline() then
    menu:addOption(loc'${GameVipListContextMenuOfflineHide}', function() GameVipList.hideOffline(true) end)
  else
    menu:addOption(loc'${GameVipListContextMenuOfflineShow}', function() GameVipList.hideOffline(false) end)
  end

  if not(GameVipList.getSortedBy() == 'name') then
    menu:addOption(f(loc'${CorelibInfoSortBy} %s', loc'${CorelibInfoName}':lower()), function() GameVipList.sortBy('name') end)
  end

  if not(GameVipList.getSortedBy() == 'status') then
    menu:addOption(f(loc'${CorelibInfoSortBy} %s', loc'${CorelibInfoStatus}':lower()), function() GameVipList.sortBy('status') end)
  end

  if not(GameVipList.getSortedBy() == 'type') then
    menu:addOption(f(loc'${CorelibInfoSortBy} %s', loc'${CorelibInfoType}':lower()), function() GameVipList.sortBy('type') end)
  end

  menu:display(mousePos)

  return true
end

function GameVipList.onVipListLabelMousePress(widget, mousePos, mouseButton)
  if mouseButton ~= MouseRightButton then
    return
  end

  local menu = g_ui.createWidget('PopupMenu')
  menu:setGameMenu(true)

  if g_game.getFeature(GameVipGroups) and widget.groupId and (widget:getId():sub(1, 6) == 'group-' or widget:getId() == 'group') then
    if widget.editable then
      local groupNameWidget = widget:getChildById('group') or widget
      menu:addOption(loc'${GameVipListContextMenuGroupEdit}', function()
        GameVipList.createEditGroupWindow(groupNameWidget:getText(), widget.groupId)
      end)
      menu:addOption(loc'${GameVipListContextMenuGroupRemove}', function()
        g_game.editVipGroups(3, widget.groupId, '')
      end)
    end
    menu:addOption(loc'${GameVipListContextMenuGroupAdd}', function() GameVipList.createAddGroupWindow() end)
    menu:display(mousePos)
    return true
  end

  menu:addOption(loc'${GameVipListContextMenuSendMsg}', function() g_game.openPrivateChannel(widget:getText()) end)
  menu:addOption(loc'${GameVipListContextMenuVipAdd}', function() GameVipList.createAddWindow() end)
  menu:addOption(f(loc'${GameVipListContextMenuVipEdit}', widget:getText()), function() if widget then GameVipList.createEditWindow(widget) end end)
  menu:addOption(f(loc'${GameVipListContextMenuVipRemove}', widget:getText()), function() if widget then GameVipList.removeVip(widget) end end)
  if g_game.getFeature(GameVipGroups) and GameVipList.showGrouped and widget.groupId then
    menu:addOption(f(loc'${GameVipListContextMenuGroupRemovePlayer}', widget:getText(), widget.groupName), function()
      GameVipList.removeVipFromGroup(widget)
    end)
  end
  menu:addSeparator()
  menu:addOption(loc'${GameVipListContextMenuCopyName}', function() g_window.setClipboardText(widget:getText()) end)

  if GameConsole and GameConsole.getOwnPrivateTab() then
    menu:addSeparator()
    menu:addOption(loc'${GameVipListContextMenuPrivateChatInvite}', function() g_game.inviteToOwnChannel(widget:getText()) end)
    menu:addOption(loc'${GameVipListContextMenuPrivateChatExclude}', function() g_game.excludeFromOwnChannel(widget:getText()) end)
  end

  if not GameVipList.isHiddingOffline() then
    menu:addOption(loc'${GameVipListContextMenuOfflineHide}', function() GameVipList.hideOffline(true) end)
  else
    menu:addOption(loc'${GameVipListContextMenuOfflineShow}', function() GameVipList.hideOffline(false) end)
  end

  if not(GameVipList.getSortedBy() == 'name') then
    menu:addOption(f(loc'${CorelibInfoSortBy} %s', loc'${CorelibInfoName}':lower()), function() GameVipList.sortBy('name') end)
  end

  if not(GameVipList.getSortedBy() == 'status') then
    menu:addOption(f(loc'${CorelibInfoSortBy} %s', loc'${CorelibInfoStatus}':lower()), function() GameVipList.sortBy('status') end)
  end

  if not(GameVipList.getSortedBy() == 'type') then
    menu:addOption(f(loc'${CorelibInfoSortBy} %s', loc'${CorelibInfoType}':lower()), function() GameVipList.sortBy('type') end)
  end

  menu:display(mousePos)

  return true
end

function GameVipList.removeVipFromGroup(widget)
  local vipId = tonumber(widget:getId():sub(4))
  local vip = g_game.getVips()[vipId]
  if not vip then
    return
  end

  local groupIds = { }
  for _, groupId in ipairs(vip[6] or { }) do
    if groupId ~= widget.groupId then
      table.insert(groupIds, groupId)
    end
  end

  g_game.editVip(vipId, vip[3] or '', vip[4] or 0, vip[5] or false, groupIds)
end

function GameVipList.createAddGroupWindow()
  if maxVipGroups < 1 then
    displayInfoBox(loc'${GameVipListGroupInfoTitle}', loc'${GameVipListGroupInfoLimitReached}')
    return
  end
  if addGroupWindow then
    return
  end
  addGroupWindow = g_ui.displayUI('addgroup')
  addGroupWindow:setText(f(loc'${GameVipListGroupWindowAddWithLimit}', maxVipGroups))
end

function GameVipList.destroyAddGroupWindow()
  if not addGroupWindow then
    return
  end

  local window = addGroupWindow
  addGroupWindow = nil
  window:destroy()
end

function GameVipList.createEditGroupWindow(groupName, groupId)
  if addGroupWindow then
    return
  end
  addGroupWindow = g_ui.displayUI('addgroup')
  addGroupWindow:setText(loc'${GameVipListGroupWindowTitleEdit}')
  addGroupWindow:getChildById('name'):setText(groupName)
  local save = function()
    local window = addGroupWindow
    local name = window:getChildById('name'):getText()
    addGroupWindow = nil
    g_game.editVipGroups(2, groupId, name)
    window:destroy()
  end
  addGroupWindow:getChildById('okButton').onClick = save
  addGroupWindow.onEnter = save
end

function GameVipList.addGroup()
  if not addGroupWindow then
    return
  end

  local window = addGroupWindow
  local name = window:getChildById('name'):getText()
  addGroupWindow = nil
  g_game.editVipGroups(1, 0, name)
  window:destroy()
end
