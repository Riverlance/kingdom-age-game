_G.GameDailyReward = { }



DailyRewardFlags = {
  OpenWindow   = 1,
  UpdateWindow = 2,
  Acquire      = 3,
}



dailyRewardWindow = nil

acquirableRewardsBar = nil
acquireButton        = nil
bonusBar             = nil

timeEvent = nil



-- Data updated from server

actualDay        = 1
accomplishedDays = 0
isRewardTaken    = false
acquireTime      = 0
elapsedTime      = 0

items = { }
for day = 1, 7 do
  items[day]               = { }
  items[day].item          = { id = 0, count = 1, title = '' }
  items[day].weekBonusItem = { id = 0, count = 1, title = '' }
end



function GameDailyReward.init()
  -- Alias
  GameDailyReward.m = modules.ka_game_dailyreward

  g_ui.importStyle('dailyrewardwindow')

  dailyRewardWindow = g_ui.createWidget('DailyRewardWindow', rootWidget)
  dailyRewardWindow:hide()
  dailyRewardWindow.onDestroy = function()
    GameDailyReward.stopTimeEvent()
  end

  acquirableRewardsBar = dailyRewardWindow.acquirableRewardsBar
  acquireButton        = dailyRewardWindow.acquireButton
  bonusBar             = dailyRewardWindow.bonusBar

  acquireButton.onClick = function(self, mousePos)
    GameDailyReward.sendAcquireRequest()
  end

  GameDailyReward.updateLayout() -- First update

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeDailyReward, GameDailyReward.parse)

  connect(g_game, {
    onGameEnd = GameDailyReward.offline,
  })

  connect(LocalPlayer, {
    onPositionChange = GameDailyReward.onPositionChange
  })
end

function GameDailyReward.terminate()
  disconnect(LocalPlayer, {
    onPositionChange = GameDailyReward.onPositionChange
  })

  disconnect(g_game, {
    onGameEnd = GameDailyReward.offline,
  })

  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeDailyReward)

  if dailyRewardWindow then
    dailyRewardWindow:destroy()
    dailyRewardWindow = nil
  end
  acquirableRewardsBar = nil
  acquireButton        = nil
  bonusBar             = nil

  _G.GameDailyReward = nil
end

function GameDailyReward.offline()
  GameDailyReward.hide()
end

function GameDailyReward.onPositionChange(creature, pos, oldPos)
  GameDailyReward.hide()
end





function GameDailyReward.updateLayout()
  local remainingTime = math.max(0, acquireTime - elapsedTime)
  local dayProgress   = acquireTime > 0 and (1 - (remainingTime / acquireTime)) * 100 or 0
  local isDayDone     = dayProgress >= 100
  local isBonusWeek   = accomplishedDays > 7 or actualDay == 7 and accomplishedDays == 7 and isRewardTaken or actualDay == 1 and accomplishedDays == 7 -- More than 1 week, week last day accomplished and taken, week first day after 7 accomplished

  for day = 1, 7 do
    local isPastDay         = day < actualDay
    local isToday           = day == actualDay
    local isFutureDay       = day > actualDay
    local isTodayDone       = isToday and isDayDone
    local phaseMiddleMargin = GameDailyReward.getPhaseMiddleMargin(acquirableRewardsBar, day)

    -- Reward item
    local rewardItemWidget      = dailyRewardWindow['rewardItem' .. day]
    local rewardItemFrameWidget = dailyRewardWindow['rewardItem' .. day .. 'Frame'] -- Frame just for create a tooltip on each item
    rewardItemWidget:setMarginLeft(acquirableRewardsBar.bgBorderLeft + phaseMiddleMargin - math.floor(rewardItemWidget:getWidth() / 2))
    if isBonusWeek then
      if rewardItemWidget:getItemId() ~= items[day].weekBonusItem.id or rewardItemWidget:getItemCount() ~= items[day].weekBonusItem.count then
        rewardItemWidget:setItemId(items[day].weekBonusItem.id)
        rewardItemWidget:setItemCount(items[day].weekBonusItem.count)
        rewardItemFrameWidget:setTooltip(items[day].weekBonusItem.title)
      end
    else
      if rewardItemWidget:getItemId() ~= items[day].item.id or rewardItemWidget:getItemCount() ~= items[day].item.count then
        rewardItemWidget:setItemId(items[day].item.id)
        rewardItemWidget:setItemCount(items[day].item.count)
        rewardItemFrameWidget:setTooltip(items[day].item.title)
      end
    end
    rewardItemWidget.blueLabel:setVisible(not isPastDay and (not isTodayDone or not isRewardTaken))
    rewardItemWidget.blueLabelText:setVisible(not isPastDay and (not isTodayDone or not isRewardTaken))
    if not isPastDay then
      rewardItemWidget.blueLabelText:setText(day)
    end
    rewardItemWidget:setEnabled(isToday and not isRewardTaken)
    rewardItemWidget:setOn(isBonusWeek)

    -- Next widgets
    if day < 7 then
      local nextWidget = dailyRewardWindow['nextWidget' .. day]
      nextWidget:setMarginLeft(acquirableRewardsBar.bgBorderLeft + GameDailyReward.getPhaseMargin(acquirableRewardsBar, day) - math.floor(nextWidget:getWidth() / 2))

      nextWidget:setOn(isPastDay or isTodayDone and isRewardTaken)
      nextWidget:setEnabled(isPastDay or isTodayDone and isRewardTaken)
    end

    -- Reward check icon
    local rewardIconCheck = dailyRewardWindow['rewardIconCheck' .. day]
    rewardIconCheck:setMarginLeft(acquirableRewardsBar.bgBorderLeft + phaseMiddleMargin - math.floor(rewardIconCheck:getWidth() / 2))
    rewardIconCheck:setOn(isPastDay or isTodayDone)

    -- Reward lock icon
    if day > 1 then
      local rewardLockCheck = dailyRewardWindow['rewardIconLock' .. day]
      rewardLockCheck:setMarginLeft(acquirableRewardsBar.bgBorderLeft + phaseMiddleMargin - math.floor(rewardLockCheck:getWidth() / 2))
      rewardLockCheck:setOn(isFutureDay)
    end

    -- Time label
    local timeLabel = dailyRewardWindow.timeLabel
    timeLabel:setText(string.format('Remaining time: %.2d:%.2d:%.2d', remainingTime / (60 * 60), (remainingTime / 60) % 60, remainingTime % 60))

    if isToday then
      if not isDayDone then
        acquireButton:setEnabled(false)
        acquirableRewardsBar:setTooltip("You have not played enough yet to get today's reward.", TooltipType.textBlock)
      elseif isRewardTaken then
        acquireButton:setEnabled(false)
        acquirableRewardsBar:setTooltip("You have taken today's reward already.", TooltipType.textBlock)
      else
        acquireButton:setEnabled(true)
        acquirableRewardsBar:setTooltip("You are now able to get today's reward.", TooltipType.textBlock)
      end

      local bonusTooltipText
      if isBonusWeek then
        bonusTooltipText = 'You are able to get the bonus on each daily reward!'
      else
        bonusTooltipText = 'You are not able to get the bonus on each daily reward yet.'
        if accomplishedDays < 7 then
          bonusTooltipText = bonusTooltipText .. '\n' .. string.format('* Days to get the bonus: %d', math.max(0, 7 - accomplishedDays))
        elseif actualDay == 7 and accomplishedDays == 7 and not isRewardTaken then
          bonusTooltipText = bonusTooltipText .. '\n' .. '* You need to get the last item of week to enable the bonus.'
        end
      end
      bonusBar:setTooltip(bonusTooltipText, TooltipType.textBlock)
    end

    GameDailyReward.setRewardProgress(dayProgress)
    GameDailyReward.setBonusProgress(dayProgress)
  end
end

function GameDailyReward.show()
  dailyRewardWindow:show()
  dailyRewardWindow:focus()
  GameDailyReward.initTimeEvent()
end

function GameDailyReward.hide()
  dailyRewardWindow:hide()
  GameDailyReward.stopTimeEvent()
end

function GameDailyReward.toggle()
  if dailyRewardWindow:isVisible() then
    GameDailyReward.hide()
  else
    GameDailyReward.show()
  end
end

function GameDailyReward.initTimeEvent()
  removeEvent(timeEvent)
  timeEvent = cycleEvent(function()
    if not dailyRewardWindow:isVisible() then
      return
    end

    elapsedTime = elapsedTime + 1

    local remainingTime = math.max(0, acquireTime - elapsedTime)
    if remainingTime < 1 then
      --[[
        The server should update the information once it gets remainingTime as 0,
        because it means that the accomplishedDays increased by 1 (has changed on server, but not on client yet).
        If you remove this check, it may wrongly draw one frame on stuffs that depends of accomplishedDays to draw
        (e.g., bonus progress) because the accomplishedDays was not updated on client yet.
      ]]
      return
    end

    GameDailyReward.updateLayout()
  end, 1000)
end

function GameDailyReward.stopTimeEvent()
  removeEvent(timeEvent)
  timeEvent = nil
end



function GameDailyReward.getPhaseMargin(barWidget, phaseId)
  local rewardSliceWidth = (barWidget:getWidth() - (barWidget.bgBorderLeft + barWidget.bgBorderRight)) / 7

  return rewardSliceWidth * phaseId
end

function GameDailyReward.getPhaseMiddleMargin(barWidget, phaseId)
  local rewardSliceWidth     = (barWidget:getWidth() - (barWidget.bgBorderLeft + barWidget.bgBorderRight)) / 7
  local halfRewardSliceWidth = rewardSliceWidth / 2

  return rewardSliceWidth * phaseId - halfRewardSliceWidth
end

function GameDailyReward.setActualDay(day)
  actualDay = day
end

function GameDailyReward.setAccomplishedDays(days)
  accomplishedDays = days
end

function GameDailyReward.setRewardTaken(on)
  isRewardTaken = on
end

function GameDailyReward.setAcquireTime(time)
  acquireTime = time
end

function GameDailyReward.setElapsedTime(time)
  elapsedTime = time
end

function GameDailyReward.setRewardProgress(dayPercent)
  local progress
  if actualDay < 7 or dayPercent < 100 then
    progress = math.max(0, actualDay - 1) * (100 / 7) + (dayPercent / 7)
  else
    progress = 100
  end
  acquirableRewardsBar:setPercent(progress)
end

function GameDailyReward.setBonusProgress(dayPercent)
  local progress
  if dayPercent >= 100 then -- accomplishedDays increased, so we need to change dayPercent to 0
    dayPercent = 0
  end
  if accomplishedDays < 7 then
    progress = accomplishedDays * (100 / 7) + (dayPercent / 7)
  else
    progress = 100
  end
  bonusBar:setPercent(progress)
end



-- Server to client

local function getWindowData(msg)
  GameDailyReward.setActualDay(msg:getU8())
  GameDailyReward.setAccomplishedDays(msg:getU32())
  GameDailyReward.setRewardTaken(msg:getU8() == 1)

  GameDailyReward.setAcquireTime(msg:getU32())
  GameDailyReward.setElapsedTime(msg:getU32())

  for day = 1, 7 do
    items[day].item.id             = msg:getU16()
    items[day].item.count          = msg:getU16()
    items[day].item.title          = msg:getString()
    items[day].weekBonusItem.id    = msg:getU16()
    items[day].weekBonusItem.count = msg:getU16()
    items[day].weekBonusItem.title = msg:getString()
  end
end

function GameDailyReward.parse(protocolGame, opcode, msg)
  local flag = msg:getU8()
  if flag == DailyRewardFlags.OpenWindow then
    getWindowData(msg)
    GameDailyReward.updateLayout()
    GameDailyReward.show()
  elseif flag == DailyRewardFlags.UpdateWindow then
    getWindowData(msg)
    if dailyRewardWindow:isVisible() then
      GameDailyReward.updateLayout()
    end
  else
    print_traceback(string.format('[Warning - ServerGameDailyReward] Unknown flag [id: %d]', flag))
  end
end

-- Client to server

function GameDailyReward.sendAcquireRequest()
  if not g_game.canPerformGameAction() then
    return
  end

  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeDailyReward)

  msg:addU8(DailyRewardFlags.Acquire)

  protocolGame:send(msg)
end
