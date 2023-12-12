---------------------------
-- Condition checking whether the player has the specified number of strategems.
-- @class module
-- @name StrategemCountCondition

local serializer_util = require('cylibs/util/serializer_util')
local Condition = require('cylibs/conditions/condition')

local StrategemCountCondition = setmetatable({}, { __index = Condition })
StrategemCountCondition.__index = StrategemCountCondition
StrategemCountCondition.__type = "StrategemCountCondition"
StrategemCountCondition.__class = "StrategemCountCondition"

function StrategemCountCondition.new(strategem_count, operator)
    local self = setmetatable(Condition.new(windower.ffxi.get_player().index), StrategemCountCondition)
    self.strategem_count = strategem_count
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function StrategemCountCondition:is_satisfied(target_index)
    return self:eval(player_util.get_current_strategem_count(), self.strategem_count, self.operator)
end

function StrategemCountCondition:tostring()
    return "StrategemCountCondition"
end

function StrategemCountCondition:serialize()
    return "StrategemCountCondition.new(" .. serializer_util.serialize_args(self.strategem_count, self.operator) .. ")"
end

function StrategemCountCondition:__eq(otherItem)
    return otherItem.__class == StrategemCountCondition.__class
            and self.strategem_count == otherItem.strategem_count
            and self.operator == otherItem.operator
end

return StrategemCountCondition




