-- Note: To use tooltip on labels, use 'phantom: false' at the label widget

-- TODO:
-- - Be able to update data without reshowing the tooltip (ex, positionLabel of minimap when you walk keeping your mouse hovered on it)

-- @docclass

local fadeInTime  = 100
local fadeOutTime = 100

local currentTooltip
local currentHoveredWidget



g_tooltip = { }



Tooltip = {
  widget = nil,
  type   = TooltipType.default,



  onTooltipShow   = function(self, hoveredWidget) end,
  onTooltipShown  = function(self, hoveredWidget) end,
  onTooltipHide   = function(self, currentHoveredWidget) end, -- (self[, currentHoveredWidget])
  onTooltipHidden = function(self, currentHoveredWidget) end, -- (self[, currentHoveredWidget])



  __listById = { },



  __className = 'Tooltip',

  __onCall = function(self, value)
    -- Get object by id
    if type(value) == 'number' then
      return self.__listById[value]
    end
  end,

  __onNew = function(self, obj)
    assert(obj.widget, '[Tooltip] Widget not defined.')

    -- Attach to list - List by id
    table.insert(self.__listById, obj)

    -- Hide widget
    obj.widget:hide()
  end,
}

setClass(Tooltip)



local function onTooltipMove(firstShow)
  local currentTooltipWidget = currentTooltip and currentTooltip.widget
  if not currentTooltipWidget or not firstShow and (not currentTooltipWidget:isVisible() or currentTooltipWidget:getOpacity() < 0.1) then
    return
  end

  local pos        = g_window.getMousePosition()
  local windowSize = g_window.getSize()
  local labelSize  = currentTooltipWidget:getSize()

  pos.x = pos.x + 1
  pos.y = pos.y + 1

  if windowSize.width - (pos.x + labelSize.width) < 10 then
    pos.x = pos.x - labelSize.width - 3
  else
    pos.x = pos.x + 10
  end

  if windowSize.height - (pos.y + labelSize.height) < 10 then
    pos.y = pos.y - labelSize.height - 3
  else
    pos.y = pos.y + 10
  end

  currentTooltipWidget:setPosition(pos)
end

function Tooltip:show(hoveredWidget)
  if not hoveredWidget:hasTooltip() then
    return
  end

  local isDefaultTooltipType = self.type == TooltipType.default

  currentHoveredWidget = hoveredWidget
  currentTooltip       = self

  if isDefaultTooltipType then
    self.widget:setText(hoveredWidget['tooltip'])
  end

  onTooltipMove(true) -- Set first position

  -- Callback
  self:onTooltipShow(hoveredWidget)
  if hoveredWidget.onTooltipShow then
    hoveredWidget:onTooltipShow(self)
  end

  self.widget:raise()
  self.widget:show()
  self.widget:enable()

  g_effects.fadeIn(self.widget, fadeInTime)

  -- Callback
  self:onTooltipShown(hoveredWidget)
  if hoveredWidget.onTooltipShown then
    hoveredWidget:onTooltipShown(self)
  end

  connect(rootWidget, {
    onMouseMove = onTooltipMove,
  })
end

function Tooltip:hide() -- Usable as Tooltip.hide() also
  if not self then
    if currentTooltip then
      currentTooltip:hide()

      currentHoveredWidget = nil
      currentTooltip       = nil
    end
    return
  end

  if not self.widget:isVisible() then
    return
  end

  -- Callback
  self:onTooltipHide(currentHoveredWidget)
  if currentHoveredWidget and currentHoveredWidget.onTooltipHide then
    currentHoveredWidget:onTooltipHide(self)
  end

  g_effects.fadeOut(self.widget, fadeOutTime)

  disconnect(rootWidget, {
    onMouseMove = onTooltipMove,
  })

  -- Callback
  self:onTooltipHidden(currentHoveredWidget)
  if currentHoveredWidget and currentHoveredWidget.onTooltipHidden then
    currentHoveredWidget:onTooltipHidden(self)
  end
end



local function onWidgetStyleApply(widget, styleName, styleNode) -- Create from .otui file
  if not styleNode['tooltip'] then
    return
  end

  widget:setTooltip(styleNode['tooltip'], styleNode['tooltip-type']) -- tooltip-type can be nil
end

local function onWidgetUpdateHover(widget, hovered)
  if widget.onTooltipHoverChange and not widget:onTooltipHoverChange(hovered) then
    return
  end

  if hovered then
    if widget:hasTooltip() and not g_mouse.isPressed() and widget:isVisible() and widget:isEnabled() then
      widget:getTooltipObject():show(widget)
    end
  else
    Tooltip.hide()
  end
end

function g_tooltip.init()
  connect(UIWidget, {
    onStyleApply  = onWidgetStyleApply,
    onHoverChange = onWidgetUpdateHover,
  })

  addEvent(function()
    -- Import tooltip type styles
    g_ui.importStyle('tooltip/default')
    g_ui.importStyle('tooltip/textblock')
    g_ui.importStyle('tooltip/image')
    g_ui.importStyle('tooltip/conditionbutton')
    g_ui.importStyle('tooltip/powerbutton')

    -- Create tooltip types

    -- Default
    Tooltip.__listById[TooltipType.default] = Tooltip:new {
      type   = TooltipType.default,
      widget = g_ui.createWidget('TooltipDefault', rootWidget)
    }

    -- Text block
    Tooltip.__listById[TooltipType.textBlock] = Tooltip:new {
      type   = TooltipType.textBlock,
      widget = g_ui.createWidget('TooltipTextBlock', rootWidget),

      onTooltipShow = function(self, hoveredWidget)
        local label = self.widget:getChildById('label')

        -- Update value
        label:setText(hoveredWidget['tooltip'])

        -- Update parent height according to child size, then anchor text bottom to parent bottom
        self.widget:setHeight(label:getHeight() + label:getMarginTop() + label:getMarginBottom())
        label:addAnchor(AnchorBottom, 'parent', AnchorBottom)
      end
    }

    -- Image
    Tooltip.__listById[TooltipType.image] = Tooltip:new {
      type   = TooltipType.image,
      widget = g_ui.createWidget('TooltipImage', rootWidget),

      onTooltipShow = function(self, hoveredWidget)
        local label = self.widget:getChildById('label')

        -- Update value
        label:setWidth(table.get(hoveredWidget, 'tooltip-size', 'width') or hoveredWidget['tooltip-width'] or 0)
        label:setHeight(table.get(hoveredWidget, 'tooltip-size', 'height') or hoveredWidget['tooltip-height'] or 0)
        label:setImageSource(resolvepath(hoveredWidget['tooltip']))

        -- Update parent size according to child size, then anchor child to parent
        self.widget:setWidth(label:getWidth() + label:getMarginLeft() + label:getMarginRight())
        self.widget:setHeight(label:getHeight() + label:getMarginTop() + label:getMarginBottom())
        label:fill('parent')
      end
    }

    -- Power button
    Tooltip.__listById[TooltipType.powerButton] = Tooltip:new {
      type   = TooltipType.powerButton,
      widget = g_ui.createWidget('TooltipPowerButton', rootWidget),

      onTooltipShow = function(self, hoveredWidget)
        local localPlayer = g_game.getLocalPlayer()
        local power       = hoveredWidget.power
        local exhaustTime = power.exhaustTime / 1000
        local vocations   = hoveredWidget:getVocations()
        local manaCost    = hoveredWidget:getMana()

        local classValueWidget           = self.widget:getChildById('classValue')
        local vocationsValueWidget       = self.widget:getChildById('vocationsValue')
        local levelValueWidget           = self.widget:getChildById('levelValue')
        local manaCostLabelWidget        = self.widget:getChildById('manaCostLabel')
        local manaCostValueWidget        = self.widget:getChildById('manaCostValue')
        local cooldownValueWidget        = self.widget:getChildById('cooldownValue')
        local premiumValueWidget         = self.widget:getChildById('premiumValue')
        local descriptionWidget          = self.widget:getChildById('descriptionLabel')
        local boostNoneDescriptionWidget = self.widget:getChildById('boostNoneDescriptionLabel')
        local boostLowDescriptionWidget  = self.widget:getChildById('boostLowDescriptionLabel')
        local boostHighDescriptionWidget = self.widget:getChildById('boostHighDescriptionLabel')

        -- Icon
        local iconWidget = self.widget:getChildById('icon')
        iconWidget:setImageSource(string.format('/images/ui/power/%d_off', power.id))

        -- Name
        local nameLabel = self.widget:getChildById('name')
        nameLabel:setText(string.exists(power.name) and power.name or 'Unknown')

        -- Class icon
        local classIconWidget = self.widget:getChildById('classIcon')
        classIconWidget:setImageSource(string.format('/images/game/creature/power/type_%s', power.aggressive and 'aggressive' or 'non_aggressive'))

        -- Class name
        classValueWidget:setTextAlign(AlignRight)
        classValueWidget:setTextWrap(true)
        classValueWidget:setText(UIPowerButton.powerClass[power.class or 0])
        classValueWidget:resizeToText()

        -- Vocations
        vocationsValueWidget:setTextAlign(AlignRight)
        vocationsValueWidget:setTextWrap(true)
        vocationsValueWidget:setText(vocations)
        vocationsValueWidget:resizeToText()

        -- Level
        levelValueWidget:setTextAlign(AlignRight)
        levelValueWidget:setTextWrap(true)
        levelValueWidget:setText(power.level)
        levelValueWidget:resizeToText()

        -- Mana cost
        local isManaEnabled = not localPlayer or not localPlayer:isWarrior()
        manaCostValueWidget:setTextAlign(AlignRight)
        manaCostValueWidget:setTextWrap(isManaEnabled)
        if isManaEnabled then
          manaCostLabelWidget:setHeight(14)

          manaCostValueWidget:setText(manaCost)
          manaCostValueWidget:resizeToText()
        else
          manaCostLabelWidget:setHeight(0)
          manaCostValueWidget:setHeight(0)
        end
        manaCostLabelWidget:setVisible(isManaEnabled)
        manaCostValueWidget:setVisible(isManaEnabled)

        -- Cooldown
        cooldownValueWidget:setTextAlign(AlignRight)
        cooldownValueWidget:setTextWrap(true)
        cooldownValueWidget:setText(string.format('%s second%s', exhaustTime, exhaustTime > 1 and 's' or ''))
        cooldownValueWidget:resizeToText()

        -- Premium
        premiumValueWidget:setTextAlign(AlignRight)
        premiumValueWidget:setTextWrap(true)
        premiumValueWidget:setText(power.premium and 'Yes' or 'No')
        premiumValueWidget:resizeToText()

        -- Description
        local isDescriptionEnabled = string.exists(power.description) and true or false
        descriptionWidget:setTextAlign(AlignCenter)
        descriptionWidget:setTextWrap(isDescriptionEnabled)
        if isDescriptionEnabled then
          descriptionWidget:setText(power.description)
          descriptionWidget:resizeToText()
        else
          descriptionWidget:setHeight(0)
        end
        descriptionWidget:setVisible(isDescriptionEnabled)

        -- Boost none description
        local isBoostNoneDescriptionEnabled = string.exists(power.descriptionBoostNone) and true or false
        boostNoneDescriptionWidget:setTextAlign(AlignCenter)
        boostNoneDescriptionWidget:setTextWrap(isBoostNoneDescriptionEnabled)
        if isBoostNoneDescriptionEnabled then
          boostNoneDescriptionWidget:setText(power.descriptionBoostNone)
          boostNoneDescriptionWidget:resizeToText()
        else
          boostNoneDescriptionWidget:setHeight(0)
        end
        boostNoneDescriptionWidget:setVisible(isBoostNoneDescriptionEnabled)

        -- Boost low description
        local isBoostLowDescriptionEnabled = string.exists(power.descriptionBoostLow) and true or false
        boostLowDescriptionWidget:setTextAlign(AlignCenter)
        boostLowDescriptionWidget:setTextWrap(isBoostLowDescriptionEnabled)
        if isBoostLowDescriptionEnabled then
          boostLowDescriptionWidget:setText(power.descriptionBoostLow)
          boostLowDescriptionWidget:resizeToText()
        else
          boostLowDescriptionWidget:setHeight(0)
        end
        boostLowDescriptionWidget:setVisible(isBoostLowDescriptionEnabled)

        -- Boost high description
        local isBoostHighDescriptionEnabled = string.exists(power.descriptionBoostHigh) and true or false
        boostHighDescriptionWidget:setTextAlign(AlignCenter)
        boostHighDescriptionWidget:setTextWrap(isBoostHighDescriptionEnabled)
        if isBoostHighDescriptionEnabled then
          boostHighDescriptionWidget:setText(power.descriptionBoostHigh)
          boostHighDescriptionWidget:resizeToText()
        else
          boostHighDescriptionWidget:setHeight(0)
        end
        boostHighDescriptionWidget:setVisible(isBoostHighDescriptionEnabled)

        -- Update layout
        self.widget:updateLayout()

        -- Set new height
        self.widget:setHeight(self.widget:getContentsSize().height + self.widget:getPaddingTop() + self.widget:getPaddingBottom())
      end
    }

    -- Condition button
    Tooltip.__listById[TooltipType.conditionButton] = Tooltip:new {
      type   = TooltipType.conditionButton,
      widget = g_ui.createWidget('TooltipConditionButton', rootWidget),

      onTooltipShow = function(self, hoveredWidget)
        local c     = hoveredWidget.condition
        local clock = hoveredWidget.clock

        local itemIconWidget       = self.widget:getChildById('conditionItemIcon')
        local powerIconWidget      = self.widget:getChildById('conditionPowerIcon')
        local boostBarWidget       = self.widget:getChildById('boostBar')
        local boostLabelWidget     = self.widget:getChildById('boostLabel')
        local boostValueWidget     = self.widget:getChildById('boostValue')
        local attributeLabelWidget = self.widget:getChildById('attributeLabel')
        local attributeValueWidget = self.widget:getChildById('attributeValue')
        local durationLabelWidget  = self.widget:getChildById('durationLabel')
        local durationValueWidget  = self.widget:getChildById('durationValue')
        local ownerLabelWidget     = self.widget:getChildById('ownerLabel')
        local ownerValueWidget     = self.widget:getChildById('ownerValue')

        local isBoostEnabled = c.boost and true or false

        -- Name
        local nameLabel = self.widget:getChildById('name')
        nameLabel:setText((not c.powerName or c.name == c.powerName) and c.name or string.format('%s\n(%s)', c.name, c.powerName))

        -- Item Icon
        if c.itemId then
          itemIconWidget:setItemId(c.itemId)
          itemIconWidget:setWidth(32)
          itemIconWidget:show()
        else
          itemIconWidget:hide()
          itemIconWidget:setWidth(0)
        end

        -- Power Icon
        if c.powerId then
          powerIconWidget:setImageSource(string.format('/images/ui/power/%d_off', c.powerId))
          powerIconWidget:setWidth(32)
          powerIconWidget:show()

          if isBoostEnabled then
            boostBarWidget:setHeight(4)
            if UIConditionButton.boostColors then
              boostBarWidget:setBackgroundColor(UIConditionButton.boostColors[c.boost])
            end
          end
        else
          powerIconWidget:hide()
          powerIconWidget:setWidth(0)
          boostBarWidget:setHeight(0)
        end

        -- Combat icon
        local combatIconWidget = self.widget:getChildById('combatIcon')
        combatIconWidget:setImageSource(string.format('/images/game/creature/condition/type_%s', c.aggressive and 'aggressive' or 'non_aggressive'))

        -- Combat value
        local combatValueWidget = self.widget:getChildById('combatValue')
        combatValueWidget:setTextAlign(AlignRight)
        combatValueWidget:setText(c.aggressive and 'Aggressive' or 'Non-Aggressive')

        -- Boost
        boostValueWidget:setTextAlign(AlignRight)
        boostValueWidget:setTextWrap(isBoostEnabled)
        if isBoostEnabled then
          boostLabelWidget:setHeight(14)

          if UIConditionButton.boostNames then
            boostValueWidget:setText(string.format('%d (%s)', c.boost, UIConditionButton.boostNames[c.boost]:lower()))
            boostValueWidget:resizeToText()
          end
          if UIConditionButton.boostColors then
            boostValueWidget:setColor()
          end
        else
          boostLabelWidget:setHeight(0)
          boostValueWidget:setHeight(0)
        end
        boostValueWidget:setColor(UIConditionButton.boostColors and UIConditionButton.boostColors[c.boost] or 'white')
        boostLabelWidget:setVisible(isBoostEnabled)
        boostValueWidget:setVisible(isBoostEnabled)

        -- Attribute
        local isAttributeEnabled = c.attribute and true or false
        attributeValueWidget:setTextAlign(AlignRight)
        attributeValueWidget:setTextWrap(isAttributeEnabled)
        if isAttributeEnabled then
          attributeLabelWidget:setHeight(14)

          local attrStr = ''
          if tonumber(c.offset) > 0 then
            attrStr = string.format('%s +%s', attrStr, c.offset)
          end
          if tonumber(c.factor) ~= 1 then
            attrStr = string.format('%s x%s', attrStr, c.factor)
          end
          attributeValueWidget:setText(string.format('%s%s', ATTRIBUTE_NAMES[c.attribute], attrStr))
          attributeValueWidget:resizeToText()
        else
          attributeLabelWidget:setHeight(0)
          attributeValueWidget:setHeight(0)
        end
        attributeLabelWidget:setVisible(isAttributeEnabled)
        attributeValueWidget:setVisible(isAttributeEnabled)

        -- Duration
        local isDurationEnabled = clock and true or false
        durationValueWidget:setTextAlign(AlignRight)
        durationValueWidget:setTextWrap(isDurationEnabled)
        if isDurationEnabled then
          durationLabelWidget:setHeight(14)

          durationValueWidget:setText(clock.durationString)
          durationValueWidget:resizeToText()
        else
          durationLabelWidget:setHeight(0)
          durationValueWidget:setHeight(0)
        end
        durationLabelWidget:setVisible(isDurationEnabled)
        durationValueWidget:setVisible(isDurationEnabled)

        -- Owner
        local isOwnerEnabled = c.originId and true or false
        ownerValueWidget:setTextAlign(AlignRight)
        ownerValueWidget:setTextWrap(isOwnerEnabled)
        if isOwnerEnabled then
          ownerLabelWidget:setHeight(14)

          ownerValueWidget:setText(c.originName)
          ownerValueWidget:resizeToText()
        else
          ownerLabelWidget:setHeight(0)
          ownerValueWidget:setHeight(0)
        end
        ownerLabelWidget:setVisible(isOwnerEnabled)
        ownerValueWidget:setVisible(isOwnerEnabled)

        -- Set new height
        self.widget:setHeight(self.widget:getContentsSize().height + self.widget:getPaddingTop() + self.widget:getPaddingBottom())
      end
    }
  end)
end

function g_tooltip.terminate()
  -- Destroy tooltip types
  for k, _ in ipairs(Tooltip.__listById) do
    if Tooltip.__listById[k].widget then
      Tooltip.__listById[k].widget:destroy()
    end
    Tooltip.__listById[k] = nil
  end

  disconnect(UIWidget, {
    onStyleApply  = onWidgetStyleApply,
    onHoverChange = onWidgetUpdateHover,
  })

  currentHoveredWidget = nil

  g_tooltip = nil
end

function g_tooltip.onWidgetMouseRelease(widget, mousePos, mouseButton)
  onWidgetUpdateHover(widget, true)
end

function g_tooltip.onWidgetDestroy(widget)
  Tooltip.hide()
end

-- @}



-- @docclass UIWidget @{

function UIWidget:setTooltip(value, tooltipType) -- (value[, tooltipType = TooltipType.default])
  self['tooltip']      = value -- Text or object
  self['tooltip-type'] = tooltipType or TooltipType.default
end

function UIWidget:removeTooltip()
  self['tooltip']     = nil
  self['tooltip-type'] = nil
end

function UIWidget:getTooltip()
  return self['tooltip']
end

function UIWidget:getTooltipType()
  return self['tooltip-type'] or TooltipType.default
end

function UIWidget:getTooltipObject()
  return Tooltip(self:getTooltipType())
end

function UIWidget:hasTooltip()
  local type = self:getTooltipType()
  if type == TooltipType.default then
    return string.exists(self['tooltip'])
  end
  return self['tooltip'] and true or false
end

-- @}

g_tooltip.init()

connect(g_app, {
  onTerminate = g_tooltip.terminate
})
