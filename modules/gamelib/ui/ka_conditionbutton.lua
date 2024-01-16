-- @docclass
UIConditionButton = extends(UIWidget, 'UIConditionButton')

local barColors = { } -- Must be sorted by percentAbove
table.insert(barColors, { percentAbove = 92, color = '#00BC00' } )
table.insert(barColors, { percentAbove = 60, color = '#50A150' } )
table.insert(barColors, { percentAbove = 30, color = '#A1A100' } )
table.insert(barColors, { percentAbove =  8, color = '#BF0A0A' } )
table.insert(barColors, { percentAbove =  3, color = '#910F0F' } )
table.insert(barColors, { percentAbove = -1, color = '#850C0C' } )

UIConditionButton.boostColors    = { }
UIConditionButton.boostColors[0] = '#88888877' -- No boost
UIConditionButton.boostColors[1] = '#FF754977'
UIConditionButton.boostColors[2] = '#B770FF77'
UIConditionButton.boostColors[3] = '#70B8FF77'

UIConditionButton.boostNames    = { }
UIConditionButton.boostNames[0] = ''
UIConditionButton.boostNames[1] = 'None'
UIConditionButton.boostNames[2] = 'Low'
UIConditionButton.boostNames[3] = 'High'

function UIConditionButton.create()
  local button = UIConditionButton.internalCreate()
  button:setFocusable(false)
  return button
end

function UIConditionButton:setup(condition)
  self:setId(f('ConditionButton(%d,%d)', condition.id, condition.subId))

  local conditionBarWidget = self:getChildById('conditionBar')
  conditionBarWidget:setPhases(condition.turns or 0)
  conditionBarWidget:setPhasesBorderWidth(1)
  conditionBarWidget:setPhasesBorderColor('#ffffff77')

  if type(condition.remainingTime) == 'number' and condition.remainingTime > 0 then
    local timer = { }
    self.clock = Timer.new(timer, condition.remainingTime, '!%M:%S')
    self.clock.updateTicks = 0.1
    self.clock.onUpdate = function() self:updateConditionClock() end
  else
    conditionBarWidget:hide()
  end

  self.condition = condition
  self:updateData(condition)
end

function UIConditionButton:updateData(condition)
  -- Setup icon
  local conditionItemIconWidget = self:getChildById('conditionItemIcon')
  if condition.itemId then
    conditionItemIconWidget:setItemId(condition.itemId)
  else
    conditionItemIconWidget:setWidth(0)
  end

  local conditionPowerIconWidget = self:getChildById('conditionPowerIcon')
  if condition.powerId then
    conditionPowerIconWidget:setIcon(f('/images/ui/power/%d_off', condition.powerId))
    conditionPowerIconWidget:setBackgroundColor(UIConditionButton.boostColors[condition.boost])
  else
  -- For debug
    -- conditionIconWidget:setText(f('%d,%d', condition.id, condition.subId))
  -- Else, remove the icon
    conditionPowerIconWidget:setWidth(0) -- Comment this line if you want the debug above to work
  end

  if condition.name then
    local conditionAuxiliarWidget = self:getChildById('conditionAuxiliar')
    conditionAuxiliarWidget:setText(f('%s', condition.name))
  end

  -- Setup aggressive type
  local conditionTypeWidget = self:getChildById('conditionType')
  conditionTypeWidget:setImageSource(condition.aggressive and '/images/game/creature/condition/type_aggressive' or '/images/game/creature/condition/type_non_aggressive')

  -- Setup clock
  local conditionClockWidget = self:getChildById('conditionClock')
  if condition.remainingTime and self.clock then
    self.clock:start()
    conditionClockWidget:setText(self.clock:getString())
  end

  self:setTooltipText()
end

function UIConditionButton:updateConditionClock()
  if self.clock then
    local conditionClockWidget = self:getChildById('conditionClock')
    conditionClockWidget:setText(self.clock:getString())

    local conditionBarWidget = self:getChildById('conditionBar')
    local percent = self.clock:getPercent()
    conditionBarWidget:setPercent(percent)

    for _, v in pairs(barColors) do
      if percent > v.percentAbove then
        conditionBarWidget:setFillerBackgroundColor(v.color)
        return
      end
    end
  end
end

function UIConditionButton:onDestroy()
  if self.clock then
    self.clock:destroy()
  end
end

function UIConditionButton:setTooltipText()
  self:setTooltip(true, TooltipType.conditionButton)
end
