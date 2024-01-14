---------------------------
-- Condition checking whether the given skillchain is in the list of allowed skillchain properties (e.g. Fusion, Light)
-- @class module
-- @name SkillchainPropertyCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local SkillchainPropertyCondition = setmetatable({}, { __index = Condition })
SkillchainPropertyCondition.__index = SkillchainPropertyCondition
SkillchainPropertyCondition.__class = "SkillchainPropertyCondition"

function SkillchainPropertyCondition.new(allowed_skillchain_properties)
    local self = setmetatable(Condition.new(nil), SkillchainPropertyCondition)
    self.allowed_skillchain_properties = allowed_skillchain_properties
    return self
end

function SkillchainPropertyCondition:is_satisfied(skillchain)
    if self.allowed_skillchain_properties:contains(skillchain) then
        return true
    end
    return false
end

function SkillchainPropertyCondition:tostring()
    return "SkillchainPropertyCondition"
end

function SkillchainPropertyCondition:serialize()
    return "SkillchainPropertyCondition.new(" .. serializer_util.serialize_args(self.allowed_skillchain_properties) .. ")"
end

function SkillchainPropertyCondition:__eq(otherItem)
    return otherItem.__class == SkillchainPropertyCondition.__class
            and self.allowed_skillchain_properties == otherItem.allowed_skillchain_properties
end

return SkillchainPropertyCondition