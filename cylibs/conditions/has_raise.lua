---------------------------
-- Condition checking whether the target has received a raise.
-- @class module
-- @name HasRaiseCondition

local Condition = require('cylibs/conditions/condition')
local HasRaiseCondition = setmetatable({}, { __index = Condition })
HasRaiseCondition.__index = HasRaiseCondition
HasRaiseCondition.__type = "HasRaiseCondition"
HasRaiseCondition.__class = "HasRaiseCondition"

function HasRaiseCondition.new()
    local self = setmetatable(Condition.new(), HasRaiseCondition)
    return self
end

function HasRaiseCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local alliance = player.alliance
        if alliance then
            local party_member = alliance:get_alliance_member(target.id)
            if party_member then
                return party_member:has_raise()
            end
        end
    end
    return false
end

function HasRaiseCondition:get_config_items()
end

function HasRaiseCondition:tostring()
    return "Has raise"
end

function HasRaiseCondition.description()
    return "Has raise."
end

function HasRaiseCondition.valid_targets()
    return S{ Condition.TargetType.Ally }
end

function HasRaiseCondition:serialize()
    return "HasRaiseCondition.new()"
end

return HasRaiseCondition
