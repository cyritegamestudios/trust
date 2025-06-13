---------------------------
-- Wrapper around a roll.
-- @class module
-- @name PhantomRoll

local ConditionalCondition = require('cylibs/conditions/conditional')

local JobAbility = require('cylibs/battle/abilities/job_ability')
local PhantomRoll = setmetatable({}, {__index = JobAbility })
PhantomRoll.__index = PhantomRoll
PhantomRoll.__type = "PhantomRoll"

-------
-- Default initializer for a new Blood Pact: Ward.
-- @tparam string roll_name Name of the roll
-- @tparam list conditions List of conditions
-- @treturn PhantomRoll A blood pact ward
function PhantomRoll.new(roll_name, conditions)
    conditions = (conditions or L{}) + L{
        ConditionalCondition.new(L{
            ConditionalCondition.new(L{
                MainJobCondition.new('COR'),
                NotCondition.new(L{ HasBuffsCondition.new(L{ 'Bust', 'Bust' }, 2) })
            }, Condition.LogicalOperator.And),
            ConditionalCondition.new(L{
                NotCondition.new(L{ MainJobCondition.new('COR') }),
                NotCondition.new(L{ HasBuffCondition.new('Bust') })
            }, Condition.LogicalOperator.And),
        }, Condition.LogicalOperator.Or)
    }
    local self = setmetatable(JobAbility.new(roll_name, conditions), PhantomRoll)
    return self
end

function PhantomRoll:is_valid()
    return true
end

return PhantomRoll