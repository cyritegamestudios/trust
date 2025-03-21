local serializer_util = require('cylibs/util/serializer_util')

local GambitCondition = {}
GambitCondition.__index = GambitCondition
--GambitCondition.__class = "GambitCondition" -- don't uncomment messes up condition.should_serialize
GambitCondition.__type = "GambitCondition"

function GambitCondition.new(condition, targetType)
    local self = setmetatable({}, GambitCondition)

    self.condition = condition
    self.targetType = targetType

    return self
end

function GambitCondition:getCondition()
    return self.condition
end

function GambitCondition:getTargetType()
    return self.targetType
end

function GambitCondition:isSatisfied(target, param)
    return target and target:get_mob() and Condition.check_conditions(L{ self.condition }, target:get_mob().index, param)
end

function GambitCondition:set_editable(editable)
    self.condition:set_editable(editable)
end

function GambitCondition:is_editable()
    return self.condition:is_editable()
end

function GambitCondition:tostring()
    return self.condition:tostring()
end

function GambitCondition:should_serialize()
    return self.condition:should_serialize()
end

function GambitCondition:serialize()
    return "GambitCondition.new(" .. self.condition:serialize() .. ", " .. serializer_util.serialize(self.targetType) .. ")"
end

function GambitCondition:copy()
    return GambitCondition.new(self.condition:copy(), self:getTargetType())
end

function GambitCondition:__eq(otherItem)
    return otherItem.__type == GambitCondition.__type
            and self:getTargetType() == otherItem:getTargetType()
            and self:getCondition() == otherItem:getCondition()
end

return GambitCondition