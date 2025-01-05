local Timer = require('cylibs/util/timers/timer')

local Action = require('cylibs/actions/action')
local AsyncAction = setmetatable({}, { __index = Action })
AsyncAction.__index = AsyncAction

function AsyncAction.new(coroutine, interval, identifier, description)
    local self = setmetatable(Action.new(0, 0, 0), AsyncAction)

    self.coroutine = coroutine
    self.interval = interval
    self.identifier = identifier or os.time()
    self.description = description
    self.timer = Timer.scheduledTimer(interval or 0.05, 0.0)

    return self
end

function AsyncAction:destroy()
    Action.destroy(self)

    self.timer:destroy()
end

function AsyncAction:get_coroutine()
    return self.coroutine
end

function AsyncAction:perform()
    if self:is_cancelled() then
        self:complete(false)
        return
    end

    local work = self:get_coroutine()

    self.timer:onTimeChange():addAction(function(_)
        local status = coroutine.status(work)
        if status == 'suspended' then
            local _, success = coroutine.resume(work)
            if success then
                self:complete(true)
            end
        elseif status == 'dead' then
            self:complete(true)
        end
    end)
    self.timer:start()
end

function AsyncAction:gettype()
    return "asyncaction"
end

function AsyncAction:is_equal(action)
    if action == nil then
        return false
    end
    return self:gettype() == action:gettype() and self:getidentifier() == action:getidentifier()
end

function AsyncAction:getidentifier()
    return self.identifier
end

function AsyncAction:tostring()
    return self.description or ""
end

function AsyncAction:debug_string()
    return "AsyncAction: "..self:getidentifier()
end

return AsyncAction




