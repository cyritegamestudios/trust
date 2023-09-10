local Action = require('cylibs/actions/action')
local TestAction = setmetatable({}, { __index = Action })
TestAction.__index = TestAction

function TestAction.new(identifier, wait)
    local self = setmetatable(Action.new(0, 0, 0), TestAction)
    self.identifier = identifier or os.time()
    self.wait = wait or 0
    return self
end

function TestAction:destroy()
    Action.destroy(self)
    self.block = nil
end

function TestAction:perform()
    if self:is_cancelled() then
        self:complete(false)
        return
    end

    if self.wait > 0 then
        coroutine.sleep(self.wait)
    end

    self:complete(true)
end

function TestAction:gettype()
    return "testaction"
end

function TestAction:getrawdata()
    return nil
end

function TestAction:is_equal(action)
    if action == nil then
        return false
    end
    return self:gettype() == action:gettype() and self:getidentifier() == action:getidentifier()
end

function TestAction:getidentifier()
    return self.identifier
end

function TestAction:tostring()
    return self.description or ""
end

function TestAction:debug_string()
    return "TestAction: "..self:getidentifier()
end

return TestAction




