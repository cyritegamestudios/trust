local IpcMessage = require('cylibs/messages/ipc_message')

local PartyChatMessage = setmetatable({}, {__index = IpcMessage })
PartyChatMessage.__index = PartyChatMessage

function PartyChatMessage.new(message)
    local self = setmetatable(IpcMessage.new(message), PartyChatMessage)
    local args = self:get_args()

    self.sender_name = args[2]

    local chat_message_args = args:slice(3, args:length())
    self.chat_message = ""
    for arg in chat_message_args:it() do
        self.chat_message = self.chat_message..arg.." "
    end

    return self
end

function PartyChatMessage:get_command()
    return "party_chat"
end

function PartyChatMessage:get_sender_name()
    return self.sender_name
end

function PartyChatMessage:get_chat_message()
    return self.chat_message
end

function PartyChatMessage:tostring()
    return "PartyChatMessage %s":format(self:get_message())
end

return PartyChatMessage



