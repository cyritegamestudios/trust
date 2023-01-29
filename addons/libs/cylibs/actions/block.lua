local Action = require('cylibs/actions/action')
local BlockAction = setmetatable({}, { __index = Action })
BlockAction.__index = BlockAction

function BlockAction.new(block, identifier)
    local self = setmetatable(Action.new(0, 0, 0), BlockAction)
    self.block = block
    self.identifier = identifier or os.time()
    return self
end

function BlockAction:destroy()
    Action.destroy(self)
    self.block = nil
end

function BlockAction:perform()
    if self:is_cancelled() then
        self:complete(false)
        return
    end
    self.block()

    self:complete(true)
end

function BlockAction:gettype()
    return "blockaction"
end

function BlockAction:getrawdata()
    return nil
end

function BlockAction:copy()
    return BlockAction.new(self.block)
end

function BlockAction:is_equal(action)
    if action == nil then
        return false
    end
    return self:gettype() == action:gettype() and self:getidentifier() == action:getidentifier()
end

function BlockAction:getidentifier()
    return self.identifier
end

function BlockAction:tostring()
    return "BlockAction: "..self:getidentifier()
end

return BlockAction




