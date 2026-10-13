MAX_UINT32 = 2 ^ 32 - 1

-- Parse a non-negative integer that fits in an unsigned 32-bit value
function parseUInt32(value, maxValue)
  local number = tonumber(value)
  maxValue    = maxValue == nil and MAX_UINT32 or maxValue

  if not number or number < 0 or number > maxValue or number ~= math.floor(number) then
    return nil
  end

  return number
end
