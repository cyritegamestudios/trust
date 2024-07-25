---------------------------
-- Represents an automaton attachment set.
-- @class module
-- @name AttachmentSet
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local AttachmentSet = setmetatable({}, { __index = Condition })
AttachmentSet.__index = AttachmentSet
AttachmentSet.__type = "AttachmentSet"
AttachmentSet.__class = "AttachmentSet"

function AttachmentSet.new(headName, frameName, attachments)
    local self = setmetatable(Condition.new(), AttachmentSet)
    self.headName = headName or 'Soulsoother Head'
    self.frameName = frameName or 'Valoredge Frame'
    self.attachments = attachments or L{}
    return self
end

function AttachmentSet:getHeadName()
    return self.headName
end

function AttachmentSet:getFrameName()
    return self.frameName
end

function AttachmentSet:getAttachments()
    return self.attachments
end

function AttachmentSet:tostring()
    return "Head: "..self.headName.." Frame: "..self.frameName.." Attachments: "..self.attachments:tostring()
end

function AttachmentSet:serialize()
    return "AttachmentSet.new(" .. serializer_util.serialize_args(self.headName, self.frameName, self.attachments) .. ")"
end

return AttachmentSet




