ObjectPool = { }
ObjectPool.__index = ObjectPool

function ObjectPool.new(createFunc, resetFunc)
  return setmetatable({
    create = createFunc,
    reset = resetFunc,
    pool = { }
  }, ObjectPool)
end

function ObjectPool:get()
  local object = table.remove(self.pool)
  if not object then
    object = self.create()
  end
  return object
end

function ObjectPool:release(object)
  if self.reset then
    self.reset(object)
  end
  table.insert(self.pool, object)
end

function ObjectPool:clear()
  self.pool = { }
end
