if not bit then
  bit = { }
end

-- Keep compatibility with the upstream Bit API while preserving this client's
-- existing lowercase bit API.
Bit = bit

function bit.bit(p)
  return 2 ^ p
end

function bit.hasBit(x, p)
  return x % (p + p) >= p
end

function bit.setbit(x, p)
  return bit.hasBit(x, p) and x or x + p
end

function bit.clearbit(x, p)
  return bit.hasBit(x, p) and x - p or x
end

function Bit.bxor(a, b)
  local result = 0
  local bitVal = 1
  while a > 0 and b > 0 do
    local aMod = a % 2
    local bMod = b % 2
    if aMod ~= bMod then
      result = result + bitVal
    end
    a = math.floor(a * 0.5)
    b = math.floor(b * 0.5)
    bitVal = bitVal * 2
  end
  result = result + (a + b) * bitVal
  return result
end

function Bit.band(a, b)
  local result = 0
  local bitVal = 1
  while a > 0 and b > 0 do
    local aMod = a % 2
    local bMod = b % 2
    if aMod == 1 and bMod == 1 then
      result = result + bitVal
    end
    a = math.floor(a * 0.5)
    b = math.floor(b * 0.5)
    bitVal = bitVal * 2
  end
  return result
end
