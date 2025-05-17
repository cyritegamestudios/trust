---------------------------
-- Condition checking the target's name.
-- @class module
-- @name TargetNamesCondition

local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local TargetNamesCondition = setmetatable({}, { __index = Condition })
TargetNamesCondition.__index = TargetNamesCondition
TargetNamesCondition.__class = "TargetNamesCondition"
TargetNamesCondition.__type = "TargetNamesCondition"

function TargetNamesCondition.new(names)
    local self = setmetatable(Condition.new(), TargetNamesCondition)
    self.names = names or L{}
    return self
end

function TargetNamesCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return self.names:contains(target.name)
    end
    return false
end

function TargetNamesCondition:tostring()
    return "Target named "..localization_util.commas(self.names, 'or')
end

function TargetNamesCondition.description()
    return "Targeting mob with name."
end

function TargetNamesCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Enemy, Condition.TargetType.Ally }
end

function TargetNamesCondition:serialize()
    return "TargetNamesCondition.new(" .. serializer_util.serialize_args(self.names) .. ")"
end

return TargetNamesCondition




