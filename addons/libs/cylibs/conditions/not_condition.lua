---------------------------
-- Condition checking whether a list of conditions all return `false`.
-- @class module
-- @name NotCondition

local Condition = require('cylibs/conditions/condition')
local NotCondition = setmetatable({}, { __index = Condition })
NotCondition.__index = NotCondition

function NotCondition.new(conditions)
    local self = setmetatable(Condition.new(), NotCondition)
    self.conditions = conditions
    return self
end

function NotCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        for condition in self.conditions:it() do
            if condition:is_satisfied(target_index) then
                return false
            end
        end
    end
    return true
end

return NotCondition




