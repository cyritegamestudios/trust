require('coroutine')
require('vectors')
require('math')

local Action = require('cylibs/actions/action')
local WaitAction = setmetatable({}, { __index = Action })
WaitAction.__index = WaitAction

function WaitAction.new(x, y, z, duration)
    local self = setmetatable(Action.new(x, y, z), WaitAction)
    self.duration = duration
    self:debug_log_create(self:gettype())
    return self
end

function WaitAction:destroy()
    Action.destroy(self)

    self:debug_log_destroy(self:gettype())
end

function WaitAction:perform()
    coroutine.sleep(self.duration)

    self:complete(true)
end

function WaitAction:get_duration()
    return self.duration
end

function WaitAction:gettype()
    return "waitaction"
end

function WaitAction:getrawdata()
    local res = {}

    res.waitaction = {}
    res.waitaction.x = self.x
    res.waitaction.y = self.y
    res.waitaction.z = self.z
    res.waitaction.duration = self:get_duration()

    return res
end

function WaitAction:copy()
    return WaitAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_duration())
end

function WaitAction:tostring()
    return "WaitAction delay: %d":format(self:get_duration())
end

return WaitAction




