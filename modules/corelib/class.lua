--[[
  -- How to instance
  local obj = Class:new { params }
  local obj = Class:new({ params }, ...)

  -- How to call
  local obj = Class(value)
  local obj = Class(value, ...)

  -- How to check if object is from a class
  if obj.isExampleClass then
    print('Value obj is from class ExampleClass.')
  end
]]

function setClass(class, parentClass) -- (class[, parentClass])
  -- 'class.__className' is required
  assert(class.__className, "Parameter '__className' is required.")

  -- Set default callbacks
  class.__onCall      = class.__onCall or function() return nil end
  class.__canInstance = class.__canInstance or function() return true end
  class.__onNew       = class.__onNew or function() end

  -- Set class metatable
  setmetatable(class, {
    __index = parentClass,
    __call  = function(self, value, ...)
      if value == nil then
        value = { } -- value can be any type, but table as default
      end

      -- Callback - on call
      -- For custom calls, instead instancing an object (e.g., get object from list by key/name)
      return class:__onCall(value, ...)
    end
  })

  -- Attach 'new' function
  function class:new(value, ...)
    if value == nil then
      value = { } -- value can be table or nil (table as default)
    end

    -- 'value' should be a table value
    assert(type(value) == 'table', "Attempt to instance with non-table value.")

  -- Callback - can create
    if not class:__canInstance(value, ...) then
      return nil
    end

    local obj = setmetatable(value, { __index = class }) -- New instance

    -- Callback - on new
    class:__onNew(obj, ...)

    return obj -- Return new instance
  end

  -- Attach 'is' function
  class[string.format('is%s', class.__className)] = true
end
