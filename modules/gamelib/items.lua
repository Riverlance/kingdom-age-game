_G.ItemsDatabase = { }

function ItemsDatabase.setTier(widget, item)
  if not widget then
    return
  end

  local tierWidget = widget.tier
  if not tierWidget then
    return
  end

  local tier = type(item) == 'number' and item or (item and item:getTier()) or 0
  if tier and tier > 0 then
    local xOffset = (math.max(1, math.min(tier, 10)) - 1) * 9
    tierWidget:setImageClip({
      x = xOffset,
      y = 0,
      width = 10,
      height = 8
    })
    tierWidget:setVisible(true)
  else
    tierWidget:setVisible(false)
  end
end
