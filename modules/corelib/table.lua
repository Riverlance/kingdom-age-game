-- @docclass table

function pack(...) -- supports nil parameters
  local newArgs = { }
  local args    = {...}
  for i = 1, select('#', ...) do
    newArgs[i] = select(i, ...)
  end
  return newArgs
end

function table.dump(t, depth)
  if not depth then
    depth = 0
  end

  for k,v in pairs(t) do
    str = (' '):rep(depth * 2) .. k .. ': '
    if type(v) ~= 'table' then
      print(str .. tostring(v))
    else
      print(str)
      table.dump(v, depth+1)
    end
  end
end

function table.clear(t)
  for k,v in pairs(t) do
    t[k] = nil
  end
end

function table.copy(t)
  local ret = { }
  for k,v in pairs(t) do
    if type(v) ~= 'table' then
      ret[k] = v
    else
      ret[k] = table.copy(v)
    end
  end
  local metaTable = getmetatable(t)
  if metaTable then
    setmetatable(ret, metaTable)
  end
  return ret
end

function table.selectivecopy(t, keys)
  local res = { }
  for i,v in ipairs(keys) do
    res[v] = t[v]
  end
  return res
end

function table.addKeys(t, keys)
  for _, key in ipairs(keys) do
    if type(key) == 'table' then
      for _key = key.from, key.to do
        t[_key] = true
      end
    else
      t[key] = true
    end
  end
end

function table.merge(t, src, overwrite)
  if overwrite then
    for k,v in pairs(src) do
      t[k] = v
    end
    return t
  end

  local _t = table.copy(t)
  for k,v in pairs(src) do
    table.insert(_t, v)
  end
  return _t
end

function table.keysAsValues(t, valueAsKey)
  local ret = { }
  if valueAsKey then
    for key, v in pairs(t) do
      ret[v] = key
    end
  else
    for key, _ in pairs(t) do
      table.insert(ret, key)
    end
  end
  return ret
end

function table.valuesAsKeys(t, keyAsValue)
  local ret = { }
  if keyAsValue then
    for k, value in pairs(t) do
      ret[value] = k
    end
  else
    for _, value in pairs(t) do
      ret[value] = true
    end
  end
  return ret
end

function table.find(t, value, lowercase)
  for k,v in pairs(t) do
    if lowercase and type(value) == 'string' and type(v) == 'string' then
      if v:lower() == value:lower() then
        return k
      end
    end

    if v == value then
      return k
    end
  end
end

function table.findbykey(t, key, lowercase)
  for k,v in pairs(t) do
    if lowercase and type(key) == 'string' and type(k) == 'string' then
      if k:lower() == key:lower() then
        return v
      end
    end

    if k == key then
      return v
    end
  end
end

function table.contains(t, value)
  for _, targetColumn in pairs(t) do
    if targetColumn == value then
      return true
    end
  end

  return false
end

function table.findkey(t, key)
  if t and type(t) == 'table' then
    for k,v in pairs(t) do
      if k == key then
        return k
      end
    end
  end
end

function table.haskey(t, key)
  return table.findkey(t, key) ~= nil
end

function table.removevalue(t, value, all, force)
  for k,v in pairs(t) do
    if v == value then
      if force then
        t[k] = nil
      else
        table.remove(t, k)
        if not all then
          return true
        end
      end
    end
  end

  if not force and all then
    return true
  end
  return false
end

function table.popvalue(value)
  local index = nil
  for k,v in pairs(t) do
    if v == value or not value then
      index = k
    end
  end
  if index then
    table.remove(t, index)
    return true
  end
  return false
end

function table.compare(t, other)
  if #t ~= #other then
    return false
  end

  for k,v in pairs(t) do
    if v ~= other[k] then
      return false
    end
  end
  return true
end

function table.empty(t)
  if t and type(t) == 'table' then
    return next(t) == nil
  end
  return true
end

function table.findbyfield(t, fieldname, fieldvalue)
  for _i,subt in pairs(t) do
    if subt[fieldname] == fieldvalue then
      return subt
    end
  end
  return nil
end

function table.size(t)
  local size = 0
  for _, _ in pairs(t) do
    size = size + 1
  end
  return size
end

function table.list(t)
  local stringRet = table.concat(t, ', '):gsub(', ([^,]+)$', ' and %1') -- Returns like '1, 2 and 3'
  return stringRet -- Return only first return parameter of table.concat
end

function table.collect(t, func)
  local res = { }
  for k,v in pairs(t) do
    local a,b = func(k,v)
    if a and b then
      res[a] = b
    elseif a ~= nil then
      table.insert(res,a)
    end
  end
  return res
end

function table.insertall(t, s)
  for k,v in pairs(s) do
    table.insert(t,v)
  end
  return res
end

function table.equals(t, comp)
  if type(t) == 'table' and type(comp) == 'table' then
    for k,v in pairs(t) do
      if v ~= comp[k] then
        return false
      end
    end
  end
  return true
end

function table.random(t)
  if table.empty(t) then
    return nil
  end

  local key = math.random(#t)
  return t[key], key
end

function table.shuffle(t)
  if #t < 2 then
    return t
  end

  for i = #t, 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
  return t
end

function table.getRatedValue(t) -- Table value needs to be a table which contains a rate value: { ..., rate = 100, ... }
  local _t = table.shuffle(table.copy(t)) -- Copy and randomize for avoid that first rows have more chance than the others

  local rateFactor = 0 -- (_t[1].rate + _t[2].rate + ... + _t[n].rate)
  for _, value in ipairs(_t) do
    rateFactor = rateFactor + value.rate
  end
  if rateFactor <= 0 then
    return nil -- Cannot divide by 0 or is negative
  end

  local random        = math.random()
  local percentFactor = 1 / rateFactor

  for i = 1, #_t do
    local percentPiece = 0
    for j = 1, i do
      percentPiece = percentPiece + (_t[j].rate * percentFactor)
    end

    if random <= percentPiece then
      return _t[i]
    end
  end

  return nil
end

function table.serialize(_table, recursive) -- (table) -- Do not use the recursive param
  local _type = type(_table)
  recursive = recursive or { }

  if _type == 'nil' or _type == 'number' or _type == 'boolean' then
    return tostring(_table)
  elseif _type == 'string' then
    return string.format('%q', _table)
  elseif getmetatable(_table) then
    error('Was not possible to serialize a table that has a metatable associated with it.')
  elseif _type == 'table' then
    if table.find(recursive, _table) then
      error('Was not possible to serialize recursive tables.')
    end
    table.insert(recursive, _table)

    local s = '{'
    for k, v in pairs(_table) do
      s = string.format('%s[%s]=%s, ', s, table.serialize(k, recursive), table.serialize(v, recursive))
    end
    return string.format('%s}', s:sub(0, s:len() - 2))
  end
  error(string.format("Was not possible to serialize the value of type '%s'", _type))
end

function table.unserialize(str)
  return loadstring('return ' .. str)()
end

function table.insertChild(t, index, value)
  if index then
    table.insert(t, index, value)
  else
    table.insert(t, value)
    index = #t
  end

  if type(value) == 'table' then
    value._parent = t
    value._id = index
  end
  return index
end

function table.removeChild(t, index, recursive)
  if not t then
    return false
  end

  repeat
    t[index] = nil
    if table.size(t) == 2 then -- only parent and id values
      index = t._id
      t = t._parent
    else
      break
    end
  until not t or not recursive
  return t
end

function table.get(t, ...)
  --[[
    -- Worst way
    local zip = company and company.director and company.director.address and company.director.address.zipcode

    -- Best way
    local zip = table.get(company, 'director', 'address', 'zipcode')
  ]]
  local args = {...}

  for i = 1, #args do
    if type(t) ~= 'table' then
      return nil
    end

    t = t[args[i]]
  end

  return t
end
