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
        NotCondition.new(L{ HasBuffCondition.new('Bust') })
    }
    --[[conditions = (conditions or L{}) + L{
        ConditionalCondition.new(L{
            ConditionalCondition.new(L{
                MainJobCondition.new('COR'),
                ConditionalCondition.new(L{
                    -- have no rolls and have fewer than 2 busts
                    ConditionalCondition.new(L{
                        HasBuffsCondition.count(res.job_abilities:with_all('type', 'CorsairRoll'):map(function(roll) return roll.en end), 0, Condition.Operator.Equals),
                        HasBuffsCondition.count(L{ 'Bust' }, 2, Condition.Operator.LessThan),
                    }, Condition.LogicalOperator.Or),
                    -- have 1 roll and have no busts
                    ConditionalCondition.new(L{
                        HasBuffsCondition.count(res.job_abilities:with_all('type', 'CorsairRoll'):map(function(roll) return roll.en end), 1, Condition.Operator.Equals), -- FIXME: this returns >= num_required but needs to be equal
                        HasBuffsCondition.count(L{ 'Bust' }, 0, Condition.Operator.Equals),
                    }, Condition.LogicalOperator.And)
                }, Condition.LogicalOperator.Or),
            }, Condition.LogicalOperator.And),
            ConditionalCondition.new(L{
                NotCondition.new(L{ MainJobCondition.new('COR') }),
                NotCondition.new(L{ HasBuffCondition.new('Bust') })
            }, Condition.LogicalOperator.And),
        }, Condition.LogicalOperator.Or)
    }]]
    local self = setmetatable(JobAbility.new(roll_name, conditions), PhantomRoll)
    return self
end

function PhantomRoll:is_valid()
    return true
end

return PhantomRoll