---------------------------
-- Condition checking whether the player has the specified number of strategems.
-- @class module
-- @name StrategemCountCondition

local Condition = require('cylibs/conditions/condition')
local StrategemCountCondition = setmetatable({}, { __index = Condition })
StrategemCountCondition.__index = StrategemCountCondition

function StrategemCountCondition.new(strategem_count)
    local self = setmetatable(Condition.new(), StrategemCountCondition)
    self.strategem_count = strategem_count
    return self
end

function StrategemCountCondition:is_satisfied(target_index)
    if player_util.get_current_strategem_count() >= self.strategem_count then
        return true
    else
        return false
    end
end

function StrategemCountCondition:is_player_only()
    return true
end

function StrategemCountCondition:tostring()
    return "StrategemCountCondition"
end

return StrategemCountCondition




