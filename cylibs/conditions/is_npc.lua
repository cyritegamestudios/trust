---------------------------
-- Condition checking whether the target is an NPC.
-- @class module
-- @name IsNpcCondition

local Condition = require('cylibs/conditions/condition')
local IsNpcCondition = setmetatable({}, { __index = Condition })
IsNpcCondition.__index = IsNpcCondition
IsNpcCondition.__type = "IsNpcCondition"
IsNpcCondition.__class = "IsNpcCondition"

function IsNpcCondition.new()
    local self = setmetatable(Condition.new(), IsNpcCondition)
    return self
end

function IsNpcCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        print(target.name, target.is_npc, target.entity_type, target.spawn_type, target.valid_target)
        return target.is_npc
    end
    return false
end

function IsNpcCondition:get_config_items()
end

function IsNpcCondition:tostring()
    return "Is NPC"
end

function IsNpcCondition.description()
    return "Is NPC."
end

function IsNpcCondition.valid_targets()
    return S{ Condition.TargetType.Ally }
end

function IsNpcCondition:serialize()
    return "IsNpcCondition.new()"
end

return IsNpcCondition




