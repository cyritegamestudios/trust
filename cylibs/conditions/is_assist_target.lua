---------------------------
-- Condition checking whether a party member is the assist target.
-- @class module
-- @name IsAssistTargetCondition

local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local IsAssistTargetCondition = setmetatable({}, { __index = Condition })
IsAssistTargetCondition.__index = IsAssistTargetCondition
IsAssistTargetCondition.__type = "IsAssistTargetCondition"
IsAssistTargetCondition.__class = "IsAssistTargetCondition"

function IsAssistTargetCondition.new()
    local self = setmetatable(Condition.new(), IsAssistTargetCondition)
    return self
end

function IsAssistTargetCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party = player.party
        if party then
            local assist_target = party:get_assist_target()
            return assist_target and assist_target:get_id() == target.id
        end
    end
    return false
end

function IsAssistTargetCondition:tostring()
    return "Is assist target"
end

function IsAssistTargetCondition.description()
    return "Is assist target."
end

function IsAssistTargetCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function IsAssistTargetCondition:serialize()
    return "IsAssistTargetCondition.new(" .. serializer_util.serialize_args() .. ")"
end

return IsAssistTargetCondition