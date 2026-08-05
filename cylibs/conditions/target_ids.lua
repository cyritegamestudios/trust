---------------------------
-- Condition checking the target's id.
-- @class module
-- @name TargetIdsCondition

local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local TargetIdsCondition = setmetatable({}, { __index = Condition })
TargetIdsCondition.__index = TargetIdsCondition
TargetIdsCondition.__class = "TargetIdsCondition"
TargetIdsCondition.__type = "TargetIdsCondition"

function TargetIdsCondition.new(ids)
    local self = setmetatable(Condition.new(), TargetIdsCondition)
    self.ids = ids or L{}
    return self
end

function TargetIdsCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return self.ids:contains(target.id)
    end
    return false
end

function TargetIdsCondition:tostring()
    return "Target id "..localization_util.commas(self.ids:map(function(id) return string.format("%X", id) end), 'or')
end

function TargetIdsCondition.description()
    return "Targeting mob with id."
end

function TargetIdsCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Enemy, Condition.TargetType.Ally }
end

function TargetIdsCondition:serialize()
    return "TargetIdsCondition.new(" .. serializer_util.serialize_args(self.ids) .. ")"
end

return TargetIdsCondition
