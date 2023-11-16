---------------------------
-- Condition checking whether the player has the given Automaton attachments equipped.
-- @class module
-- @name HasAttachmentsCondition

local pup_util = require('cylibs/util/pup_util')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local HasAttachmentsCondition = setmetatable({}, { __index = Condition })
HasAttachmentsCondition.__index = HasAttachmentsCondition
HasAttachmentsCondition.__type = "HasAttachmentsCondition"

function HasAttachmentsCondition.new(attachment_names)
    local self = setmetatable(Condition.new(), HasAttachmentsCondition)
    self.attachment_names = attachment_names
    return self
end

function HasAttachmentsCondition:is_satisfied(target_index)
    for attachment_name in self.attachment_names:it() do
        if pup_util.get_attachments():contains(attachment_name) then
            return true
        end
    end
    return false
end

function HasAttachmentsCondition:tostring()
    return "HasAttachmentsCondition"
end

function HasAttachmentsCondition:serialize()
    return "HasAttachmentsCondition.new(" .. serializer_util.serialize_args(self.attachment_names) .. ")"
end

return HasAttachmentsCondition




