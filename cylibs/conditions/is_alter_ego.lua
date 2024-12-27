---------------------------
-- Condition checking whether the target is an Alter Ego.
-- @class module
-- @name IsAlterEgoCondition

local Condition = require('cylibs/conditions/condition')
local IsAlterEgoCondition = setmetatable({}, { __index = Condition })
IsAlterEgoCondition.__index = IsAlterEgoCondition
IsAlterEgoCondition.__type = "IsAlterEgoCondition"
IsAlterEgoCondition.__class = "IsAlterEgoCondition"

function IsAlterEgoCondition.new()
    local self = setmetatable(Condition.new(), IsAlterEgoCondition)
    return self
end

function IsAlterEgoCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party = player.party
        if party then
            local party_member = party:get_party_member(target.id)
            if party_member then
                return party_member:is_trust()
            end
        end
    end
    return false
end

function IsAlterEgoCondition:get_config_items()
end

function IsAlterEgoCondition:tostring()
    return "Is alter ego"
end

function IsAlterEgoCondition.description()
    return "Is alter ego."
end

function IsAlterEgoCondition.valid_targets()
    return S{ Condition.TargetType.Ally }
end

function IsAlterEgoCondition:serialize()
    return "IsAlterEgoCondition.new()"
end

return IsAlterEgoCondition




