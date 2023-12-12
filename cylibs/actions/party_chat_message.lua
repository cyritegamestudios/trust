local Action = require('cylibs/actions/action')
local PartyChatMessageAction = setmetatable({}, { __index = Action })
PartyChatMessageAction.__index = PartyChatMessageAction

function PartyChatMessageAction.new(message, party)
    local self = setmetatable(Action.new(0, 0, 0), PartyChatMessageAction)
    self.message = message
    return self
end

function PartyChatMessageAction:destroy()
    Action.destroy(self)
end

function PartyChatMessageAction:perform()
    windower.chat.input('/p '..self.message)

    self:complete(true)
end

function PartyChatMessageAction:gettype()
    return "partychatmessage"
end

function PartyChatMessageAction:getidentifier()
    return self.message
end

function PartyChatMessageAction:tostring()
    return self.message
end

function PartyChatMessageAction:debug_string()
    return "PartyChatMessageAction: "..self:getidentifier()
end

return PartyChatMessageAction




