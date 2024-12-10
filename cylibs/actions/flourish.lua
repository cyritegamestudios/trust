---------------------------
-- Action representing a flourish
-- @class module
-- @name Flourish

local JobAbility = require('cylibs/actions/job_ability')
local Flourish = setmetatable({}, {__index = JobAbility })
Flourish.__index = Flourish
Flourish.__class = "Flourish"

function Flourish.new(flourish_name, target_index)
    local conditions = L{
        HasBuffsCondition.new(L{ "Finishing Move 1", "Finishing Move 2", "Finishing Move 3", "Finishing Move 4", "Finishing Move 5", "Finishing Move (6+)" }, 1, windower.ffxi.get_player().index),
        ValidTargetCondition.new()
    }
    local self = setmetatable(JobAbility.new(0, 0, 0, flourish_name, target_index, conditions), Flourish)
    return self
end

function Flourish:gettype()
    return "flourishaction"
end

function Flourish:debug_string()
    return "Flourish: %s":format(self:get_job_ability_name())
end

return Flourish