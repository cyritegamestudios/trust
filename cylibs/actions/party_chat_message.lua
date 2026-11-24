local Action = require('cylibs/actions/action')
local PartyChatMessageAction = setmetatable({}, { __index = Action })
PartyChatMessageAction.__index = PartyChatMessageAction

function PartyChatMessageAction.new(message, party)
    local self = setmetatable(Action.new(0, 0, 0), PartyChatMessageAction)
    self.message = message
    -- Kept so perform() can re-check the party at fire time: the
    -- enqueue-time guard cannot see the party emptying while the
    -- message waits in the queue.
    self.party = party
    return self
end

function PartyChatMessageAction:destroy()
    Action.destroy(self)
end

function PartyChatMessageAction:perform()
    -- The party may have emptied between enqueue and fire (up to ~12.5s
    -- with a full queue); /p with no party errors in game, so fall back
    -- to a local message instead. A nil party keeps the old behaviour.
    if self.party and self.party:num_party_members() <= 1 then
        addon_message(260, self.message)
    else
        windower.chat.input('/p '..self.message)
    end

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




