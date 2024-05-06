
--[[
  todo:

  - checkbox list
  - values view list
  - default values
]]



_G.GameModalDialog = { }



local debugging = false

local minWidth = 200
local maxWidth = 800

local choiceHeight      = 14
local minVisibleChoices = 1
local maxVisibleChoices = 10

local checkBoxHeight       = 14
local minVisibleCheckBoxes = 1
local maxVisibleCheckBoxes = 10

local fieldHeight      = 22
local minVisibleFields = 1
local maxVisibleFields = 5

local buttonSpacing = 2



-- Class

do
  -- ModalDialog

  do
    -- Values to keep after reload
    local __listById
    if ModalDialog then -- Previous object on reload
      -- Copy old data
      __listById = ModalDialog.__listById
    end



    ModalDialog = createClass{
      id          = 0,
      spectatorId = 0,

      title   = '',
      message = '',

      width  = 0,
      height = 0,

      enterButton  = 0,
      escapeButton = 0,

      priority = false,

      choices    = { },
      checkBoxes = { },
      fields     = { },
      buttons    = { },



      -- Data
      widget = nil,



      -- List with all dialogs
      __listById = __listById or { },
    }



    -- Base

    do
      function ModalDialog:__onCall(value)
        -- Get object by id
        if type(value) == 'number' then
          return ModalDialog.__listById[value]
        end
      end

      function ModalDialog:__onNew(obj)
        if self.__listById[obj.id] then
          return
        end

        -- Attach to list - List by id
        self.__listById[obj.id] = obj

        -- Show dialog
        obj:show()
      end

      function ModalDialog:destroy() -- modalDialog:destroy() or ModalDialog.destroy()
        if not self then
          ModalDialog.forEach(function(dialog)
            dialog:destroy()
          end)

          ModalDialog.__listById = { }

          return
        end

        -- Hide dialog
        self:hide()

        -- Detach from list - List by id
        ModalDialog.__listById[self.id] = nil
      end

      function ModalDialog.forEach(callback)
        for _, dialog in pairs(ModalDialog.__listById) do
          if callback(dialog) then
            return dialog
          end
        end
      end
    end



    -- Get attributes

    do
      function ModalDialog:getFocusedChoice()
        local choiceList = self.widget.choiceList

        local focusedChoice = choiceList:getFocusedChild()
        if not focusedChoice then
          return nil
        end

        return focusedChoice
      end

      function ModalDialog:getCheckBoxValues()
        local values       = { }
        local checkBoxList = self.widget.checkBoxList

        for k, checkBox in ipairs(checkBoxList:getChildren()) do
          values[k] = checkBox:isChecked()
        end

        return values
      end

      function ModalDialog:getFieldsText()
        local texts     = { }
        local fieldList = self.widget.fieldList

        for k, field in ipairs(fieldList:getChildren()) do
          texts[k] = field:getText()
        end

        return texts
      end

      function ModalDialog:getButtonText(buttonId)
        local text = ''

        local buttonList = self.widget.buttonsPanel

        for _, button in ipairs(buttonList:getChildren()) do
          if (button.buttonId or 0) == buttonId then
            text = button.buttonText
            break
          end
        end

        return text
      end

      function ModalDialog:getGoalWidth()
        if self.width > 0 then
          return math.max(minWidth, self.width)
        end

        local widget            = self.widget
        local choiceList        = widget.choiceList
        local choiceScrollBar   = widget.choiceScrollBar
        local checkBoxList      = widget.checkBoxList
        local checkBoxScrollBar = widget.checkBoxScrollBar
        local buttonsPanel      = widget.buttonsPanel

        local choicesWidth = 0
        for _, choice in ipairs(choiceList:getChildren()) do
          choicesWidth = math.max(choice:getTextSize().width + choice:getTextOffset().x * 2 + (string.exists(choice.choiceTooltip) and choice.infoButton:getWidth() or 0), choicesWidth)
        end

        local checkBoxesWidth = 0
        for _, checkBox in ipairs(checkBoxList:getChildren()) do
          checkBoxesWidth = math.max(checkBox:getTextSize().width + checkBox:getTextOffset().x + (string.exists(checkBox.checkBoxTooltip) and checkBox.infoButton:getWidth() or 0), checkBoxesWidth)
        end

        return math.min(math.max(minWidth, math.max(widget:getTextSize().width, choiceList:getPaddingLeft() + choicesWidth + choiceList:getPaddingRight() + choiceScrollBar:getWidth(), checkBoxList:getPaddingLeft() + checkBoxesWidth + checkBoxList:getPaddingRight() + checkBoxScrollBar:getWidth(), buttonsPanel:getWidth()) + 20), maxWidth)
      end

      function ModalDialog:getGoalHeight()
        if self.height > 0 then
          return self.height
        end

        local widget            = self.widget
        local messageLabel      = widget.messageLabel
        local guideLine1        = widget.guideLine1
        local choiceScrollBar   = widget.choiceScrollBar
        local guideLine2        = widget.guideLine2
        local checkBoxScrollBar = widget.checkBoxScrollBar
        local guideLine3        = widget.guideLine3
        local fieldScrollBar    = widget.fieldScrollBar
        local bottomSeparator   = widget.bottomSeparator
        local buttonsPanel      = widget.buttonsPanel

        return widget:getPaddingTop() +
               messageLabel:getHeight() +
               guideLine1:getMarginTop() +
               choiceScrollBar:getHeight() +
               guideLine2:getMarginTop() +
               checkBoxScrollBar:getHeight() +
               guideLine3:getMarginTop() +
               fieldScrollBar:getHeight() +
               10 + bottomSeparator:getHeight() + bottomSeparator:getMarginBottom() +
               buttonsPanel:getHeight() +
               widget:getPaddingBottom()
      end
    end



    -- Set attributes

    do
      function ModalDialog:setMessageLabel(updateLayout) -- (updateLayout = true)
        if updateLayout == nil then
          updateLayout = true
        end

        local messageLabel = self.widget.messageLabel

        messageLabel:setText(tr(self.message))
        messageLabel:setTextWrap(true)
        messageLabel:resizeToText()
        messageLabel:setVisible(string.exists(messageLabel:getText()))

        -- Update layout
        if updateLayout then
          self:updateLayout()
        end
      end

      function ModalDialog:setChoices(updateLayout) -- (updateLayout = true)
        if updateLayout == nil then
          updateLayout = true
        end

        local widget          = self.widget
        local choices         = self.choices
        local choiceList      = widget.choiceList
        local choiceScrollBar = widget.choiceScrollBar

        for i = 1, #choices do
          local choiceId      = choices[i][1]
          local choiceText    = choices[i][2]
          local choiceTooltip = choices[i][3]

          local label         = g_ui.createWidget('ModalChoice', choiceList)
          label.choiceId      = choiceId
          label.choiceText    = choiceText
          label.choiceTooltip = choiceTooltip

          label:setText(choiceText)
          label:setPhantom(false)

          -- Tooltip
          if string.exists(choiceTooltip) then
            local text = f("%s\n%s", choiceText, choiceTooltip)
            label.infoButton:setTooltip(text, TooltipType.textBlock)
            label.infoButton:show()
          else
            label.infoButton:removeTooltip()
            label.infoButton:hide()
          end
        end

        -- Visible
        if #choices > 0 then
          choiceList:setVisible(true)
          choiceList:setFocusable(true)

          local choicesSizeAmount = math.min(math.max(minVisibleChoices, #choices), maxVisibleChoices)
          choiceScrollBar:setHeight(choicesSizeAmount * choiceHeight + choiceList:getPaddingTop() + choiceList:getPaddingBottom())
          choiceScrollBar:setVisible(#choices > maxVisibleChoices)

        -- Hidden
        else
          choiceList:setVisible(false)
          choiceScrollBar:setVisible(false)
          choiceScrollBar:setHeight(0)
        end

        -- Keys
        g_keyboard.bindKeyPress('Up', function() choiceList:focusPreviousChild(KeyboardFocusReason) end, widget)
        g_keyboard.bindKeyPress('Down', function() choiceList:focusNextChild(KeyboardFocusReason) end, widget)

        -- Update layout
        if updateLayout then
          self:updateLayout()
        end
      end

      function ModalDialog:setCheckBoxes(updateLayout) -- (updateLayout = true)
        if updateLayout == nil then
          updateLayout = true
        end

        local widget            = self.widget
        local checkBoxes        = self.checkBoxes
        local checkBoxList      = widget.checkBoxList
        local checkBoxScrollBar = widget.checkBoxScrollBar

        for i = 1, #checkBoxes do
          local checkBoxId      = checkBoxes[i][1]
          local checkBoxText    = checkBoxes[i][2]
          local checkBoxTooltip = checkBoxes[i][3]

          local checkBox           = g_ui.createWidget('ModalCheckBox', checkBoxList)
          checkBox.checkBoxId      = checkBoxId
          checkBox.checkBoxText    = checkBoxText
          checkBox.checkBoxTooltip = checkBoxTooltip

          checkBox:setText(checkBoxText)

          -- Tooltip
          if string.exists(checkBoxTooltip) then
            local text = f("%s\n%s", checkBoxText, checkBoxTooltip)
            checkBox.infoButton:setTooltip(text, TooltipType.textBlock)
            checkBox.infoButton:show()
          else
            checkBox.infoButton:removeTooltip()
            checkBox.infoButton:hide()
          end
        end

        -- Visible
        if #checkBoxes > 0 then
          checkBoxList:setVisible(true)

          local checkBoxesSizeAmount = math.min(math.max(minVisibleCheckBoxes, #checkBoxes), maxVisibleCheckBoxes)
          checkBoxScrollBar:setHeight(checkBoxesSizeAmount * checkBoxHeight + checkBoxList:getPaddingTop() + checkBoxList:getPaddingBottom())
          checkBoxScrollBar:setVisible(#checkBoxes > maxVisibleCheckBoxes)

        -- Hidden
        else
          checkBoxList:setVisible(false)
          checkBoxScrollBar:setVisible(false)
          checkBoxScrollBar:setHeight(0)
        end

        -- Update layout
        if updateLayout then
          self:updateLayout()
        end
      end

      function ModalDialog:setFields(updateLayout) -- (updateLayout = true)
        if updateLayout == nil then
          updateLayout = true
        end

        local widget         = self.widget
        local fields         = self.fields
        local fieldList      = widget.fieldList
        local fieldScrollBar = widget.fieldScrollBar

        for i = 1, #fields do
          local fieldId       = fields[i][1]
          local fieldName     = fields[i][2]
          local fieldTooltip  = fields[i][3]
          local fieldRegex    = fields[i][4]
          local fieldMinChars = fields[i][5]
          local fieldMaxChars = fields[i][6]
          local fieldHidden   = fields[i][7]

          local field         = g_ui.createWidget('ModalField', fieldList)
          field.fieldId       = fieldId
          field.fieldName     = fieldName
          field.fieldTooltip  = fieldTooltip
          field.fieldRegex    = fieldRegex
          field.fieldMinChars = fieldMinChars
          field.fieldMaxChars = fieldMaxChars
          field.maxChars      = fieldMaxChars -- TextField typing
          field.fieldHidden   = fieldHidden

          field.regex = fieldRegex
          field:setTextHidden(fieldHidden)
          field:setPlaceholderText(fieldName)
          field:setPhantom(true)

          -- Tooltip
          if string.exists(fieldTooltip) then
            local hasMinMaxLimit = fieldMinChars > 0 and fieldMaxChars > 0
            local higherAmount   = fieldMaxChars > 0 and fieldMaxChars or fieldMinChars > 0 and fieldMinChars or 0
            local charsLimitText = (fieldMinChars > 0 or fieldMaxChars > 0) and f("\nLimit: %s%s%s character%s.", fieldMinChars > 0 and f("%d%s", fieldMinChars, not hasMinMaxLimit and " (minimum)" or '') or '', hasMinMaxLimit and ' ~ ' or '', fieldMaxChars > 0 and f("%d%s", fieldMaxChars, not hasMinMaxLimit and " (maximum)" or '') or '', higherAmount > 1 and 's' or '') or ''
            local text           = f("%s%s\n%s", fieldName, charsLimitText, fieldTooltip)
            field.infoButton:setTooltip(text, TooltipType.textBlock)
            field.infoButton:show()
          else
            field.infoButton:removeTooltip()
            field.infoButton:hide()
          end
        end

        -- Visible
        if #fields > 0 then
          fieldList:setVisible(true)
          fieldList:setFocusable(true)

          local fieldsSizeAmount = math.min(math.max(minVisibleFields, #fields), maxVisibleFields)
          fieldScrollBar:setHeight(fieldsSizeAmount * fieldHeight + fieldList:getPaddingTop() + fieldList:getPaddingBottom())
          fieldScrollBar:setVisible(#fields > maxVisibleFields)

        -- Hidden
        else
          fieldList:setVisible(false)
          fieldScrollBar:setVisible(false)
          fieldScrollBar:setHeight(0)
        end

        -- Update layout
        if updateLayout then
          self:updateLayout()
        end
      end

      function ModalDialog:setButtons(updateLayout) -- (updateLayout = true)
        if updateLayout == nil then
          updateLayout = true
        end

        local dialog       = self
        local widget       = self.widget
        local buttons      = self.buttons
        local buttonsPanel = widget.buttonsPanel

        local buttonsWidth = 0
        for i = 1, #buttons do
          local buttonId      = buttons[i][1]
          local buttonText    = buttons[i][2]
          local buttonTooltip = buttons[i][3]

          local button         = g_ui.createWidget('ModalButton', buttonsPanel)
          button.buttonId      = buttonId
          button.buttonText    = buttonText
          button.buttonTooltip = buttonTooltip

          button:setText(buttonText)
          button:setMarginLeft(buttonSpacing)

          -- Tooltip
          if string.exists(buttonTooltip) then
            button:setTooltip(buttonTooltip, TooltipType.textBlock)
          else
            button:removeTooltip()
          end

          buttonsWidth = buttonsWidth + button:getWidth()

          function button:onClick()
            dialog:answer(buttonId)
          end
        end

        -- Visible
        if #buttons > 0 then
          buttonsWidth = buttonsWidth + (#buttons - 1) * buttonSpacing

          buttonsPanel:setWidth(buttonsWidth)
          buttonsPanel:setVisible(true)
          buttonsPanel:setFocusable(false)

        -- Hidden
        else
          buttonsPanel:setVisible(false)
        end

        -- Update layout
        if updateLayout then
          self:updateLayout()
        end
      end
    end



    -- Main

    do
      function ModalDialog:updateLayout()
        local widget       = self.widget
        local messageLabel = widget.messageLabel
        local choiceList   = widget.choiceList
        local checkBoxList = widget.checkBoxList
        local fieldList    = widget.fieldList

        -- Guide lines
        do
          local message    = messageLabel:isVisible()
          local choices    = choiceList:isVisible()
          local checkBoxes = checkBoxList:isVisible()
          local fields     = fieldList:isVisible()

          widget.guideLine1:setVisible(message and choices)
          widget.guideLine2:setVisible((message or choices) and checkBoxes)
          widget.guideLine3:setVisible((message or choices or checkBoxes) and fields)
        end

        -- Update width
        widget:setWidth(self:getGoalWidth())

        -- Fix message size according to window width
        messageLabel:setTextWrap(true)
        messageLabel:resizeToText()

        -- Update height
        widget:setHeight(self:getGoalHeight())

        -- Update focus
        if choiceList:hasChildren() then
          choiceList:focusChild(choiceList:getFirstChild())
        elseif fieldList:hasChildren() then
          fieldList:focusChild(fieldList:getFirstChild())
        end
      end

      function ModalDialog:answer(buttonId)
        local widget = self.widget

        local choice     = self:getFocusedChoice()
        local choiceId   = choice and choice.choiceId or 0xFF
        local choiceText = choice and choice.choiceText or ''

        -- Is not a cancel button
        if buttonId ~= self.escapeButton then
          local fieldList = widget.fieldList

          for _, field in ipairs(fieldList:getChildren()) do
            local text = field:getText()

            -- Min characters
            if field.fieldMinChars > 0 and #text < field.fieldMinChars then
              displayErrorBox(tr("Error"), f("The text field '%s' should have at least %d character%s.", field.fieldName, field.fieldMinChars, field.fieldMinChars and 's' or ''))
              return

            -- Max characters
            elseif field.fieldMaxChars > 0 and #text > field.fieldMaxChars then
              displayErrorBox(tr("Error"), f("The text field '%s' should up to %d character%s.", field.fieldName, field.fieldMaxChars, field.fieldMaxChars and 's' or ''))
              return
            end
          end
        end

        -- Send answer to server
        g_game.answerModalDialog(self.id, buttonId, self:getButtonText(buttonId), choiceId, choiceText, self:getCheckBoxValues(), self:getFieldsText(), self.spectatorId)

        -- Destroy window
        self:destroy()
      end

      function ModalDialog:show()
        if self.priority then
          local anotherPriorityDialog = ModalDialog.forEach(function(dialog)
            if dialog ~= self and dialog.priority then
              return true
            end
          end)
          if anotherPriorityDialog then
            return false -- Can have only one priority modal dialog opened
          end
        end

        local dialog = self

        -- Create widget
        self.widget  = self.widget or g_ui.createWidget('ModalDialog', rootWidget)
        local widget = self.widget

        -- Lock
        if self.priority then
          widget:lock()
        end

        local choiceList = widget.choiceList

        -- Update data
        widget:setText(tr(self.title))
        self:setMessageLabel(false)
        self:setChoices(false)
        self:setCheckBoxes(false)
        self:setFields(false)
        self:setButtons(false)

        -- Update layout
        self:updateLayout()

        -- Event

        local function confirm()
          dialog:answer(dialog.enterButton)
        end

        -- On double click
        function choiceList:onDoubleClick()
          confirm()
        end

        -- On press enter
        function widget:onEnter()
          confirm()
        end

        -- On press escape
        function widget:onEscape()
          dialog:answer(dialog.escapeButton)
        end

        return true
      end

      function ModalDialog:hide()
        if not self.widget then
          return false
        end

        -- Unlock
        self.widget:unlock()

        -- Destroy widget
        self.widget:destroy()
        self.widget = nil

        return true
      end
    end
  end
end



-- Module

do
  function GameModalDialog.init()
    -- Alias
    GameModalDialog.m = modules.game_modaldialog

    g_ui.importStyle('modaldialog')

    connect(g_game, {
      onModalDialog       = GameModalDialog.onModalDialog,
      onModalDialogCancel = GameModalDialog.onModalDialogCancel,
      onGameEnd           = GameModalDialog.onGameEnd,
    })

    if debugging then
      ModalDialog.destroy() -- Destroy all dialogs
      ModalDialog:new{
        id          = 0,
        spectatorId = 0,

        title   = 'Lorem ipsum dolor',
        -- message = '',--'Lorem ipsum dolor sit amet ipsum dolor sit amet ipsum dolor sit amet ipsum dolor sit amet ipsum dolor sit amet.',
        message = 'Lorem ipsum dolor sit amet ipsum dolor sit amet ipsum dolor sit amet ipsum dolor sit amet ipsum dolor sit amet.',

        width  = 0, -- Optional
        height = 0, -- Optional

        enterButton  = 1, -- Button 'Ok'
        escapeButton = 2, -- Button 'Escape'

        priority = false,

        choices = {
          { 1, "Option 1", "Tooltip of option 1." },
          { 2, "Option 2", "" },
          { 3, "Option 3", "" },
        },
        checkBoxes = {
          { 1, "CheckBox 1", "Tooltip of 'CheckBox 1'."},
          { 2, "CheckBox 2", "."},
          { 3, "CheckBox 3", "'."},
        },
        fields = {
          { 1, "Name", "Letters and spaces only.", "^[%a ]+$", 4, 10, false },
          { 2, "Text", "", "", 0, 0, false },
          { 3, "Password", "Numbers only.", "^[0-9]+$", 0, 20, true },
        },
        buttons = {
          { 1, "Ok", "Tooltip of 'Ok' button." },
          { 2, "Escape", "" },
        },
      }
    end
  end

  function GameModalDialog.terminate()
    disconnect(g_game, {
      onModalDialog       = GameModalDialog.onModalDialog,
      onModalDialogCancel = GameModalDialog.onModalDialogCancel,
      onGameEnd           = GameModalDialog.onGameEnd,
    })

    ModalDialog.destroy() -- Destroy all dialogs

    _G.GameModalDialog = nil
  end
end



-- Event

do
  function GameModalDialog.onModalDialog(id, title, message, spectatorId, buttons, enterButton, escapeButton, choices, checkBoxes, fields, priority, width, height)
    ModalDialog:new{
      id          = id,
      spectatorId = spectatorId,

      title   = title,
      message = message,

      width  = width,
      height = height,

      enterButton  = enterButton,
      escapeButton = escapeButton,

      priority = priority,

      choices    = choices,
      checkBoxes = checkBoxes,
      fields     = fields,
      buttons    = buttons,
    }
  end

  function GameModalDialog.onModalDialogCancel(id)
    local dialog = ModalDialog(id)
    if dialog then
      dialog:destroy()
    end
  end

  function GameModalDialog.onGameEnd()
    ModalDialog.destroy() -- Destroy all dialogs
  end
end
