---------------------------
-- Condition checking whether the player has the maximum number of alter egos summoned.
-- @class module
-- @name HasMaxNumAlterEgosCondition

local HasKeyItemsCondition = require('cylibs/conditions/has_key_items')
local Condition = require('cylibs/conditions/condition')

local HasMaxNumAlterEgosCondition = setmetatable({}, { __index = Condition })
HasMaxNumAlterEgosCondition.__index = HasMaxNumAlterEgosCondition
HasMaxNumAlterEgosCondition.__type = "HasMaxNumAlterEgosCondition"
HasMaxNumAlterEgosCondition.__class = "HasMaxNumAlterEgosCondition"

function HasMaxNumAlterEgosCondition.new()
    local self = setmetatable(Condition.new(), HasMaxNumAlterEgosCondition)
    return self
end

function HasMaxNumAlterEgosCondition:is_satisfied(_)
    local num_alter_egos = player.party:get_party_members():filter(function(p) return p:is_trust() end):length()
    return num_alter_egos >= self:get_max_num_alter_egos()
end

function HasMaxNumAlterEgosCondition:get_max_num_alter_egos()
    if Condition.check_conditions(L{ HasKeyItemsCondition.new(L{ "\"Rhapsody in Crimson\"" }, 1, Condition.Operator.Equals) }) then
        return 5
    elseif Condition.check_conditions(L{ HasKeyItemsCondition.new(L{ "\"Rhapsody in White\"" }, 1, Condition.Operator.Equals) }) then
        return 4
    end
    return 3
end

function HasMaxNumAlterEgosCondition:get_config_items()
    return L{}
end

function HasMaxNumAlterEgosCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function HasMaxNumAlterEgosCondition:serialize()
    return "HasMaxNumAlterEgosCondition.new()"
end

function HasMaxNumAlterEgosCondition:tostring()
    return "Has"..' '..self:get_max_num_alter_egos()..' Alter Egos.'
end

function HasMaxNumAlterEgosCondition.description()
    return "Has max Alter Egos."
end

function HasMaxNumAlterEgosCondition:__eq(otherItem)
    return otherItem.__class == HasMaxNumAlterEgosCondition.__class
end

return HasMaxNumAlterEgosCondition




