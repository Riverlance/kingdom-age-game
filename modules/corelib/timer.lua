Timer = { --minute:second countdown timer
    spentTime = 0,
    updateTicks = 1,
    onUpdate = nil,
    forward = false,
}

function Timer:new(duration, format)
    local timer = { }
    timer.startTime = os.time()
    timer.duration = math.floor(duration / 1000)
    timer.endTime = timer.startTime + timer.duration
    timer.format = format or '!%X'
    return setmetatable(timer, { __index = Timer })
end

function Timer:getString(format)
    if self.forward then
        return os.date(format or self.format, os.difftime(os.time(), self.startTime))
    end
    return os.date(format or self.format, os.difftime(self.endTime, os.time()))
end

function Timer:getDurationString(format)
    return os.date(format or self.format, os.difftime(self.endTime, self.startTime))
end

function Timer:getPercent()
    if self.forward then
        return 100 * self.spentTime / self.duration
    end
    return 100 - 100 * self.spentTime / self.duration
end

function Timer:getRemainingTime()
    return self.duration - self.spentTime
end

function Timer:start()
    self.event = cycleEvent(function() self:update() end, self.updateTicks * 1000)
end

function Timer:stop()
    self.event:cancel()
end

function Timer:destroy()
    self:stop()
    self.onUpdate = nil
end

function Timer:update()
    self.spentTime = self.spentTime + self.updateTicks

--countdown
    if self.spentTime > self.duration then
        self:stop()
        return
    end

    if self.onUpdate then
        self:onUpdate()
    end
end

