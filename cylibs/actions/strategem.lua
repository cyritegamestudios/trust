---------------------------
-- Action representing the player using a strategem.
-- @class module
-- @name Strategem

local JobAbility = require('cylibs/actions/job_ability')
local Strategem = setmetatable({}, {__index = JobAbility })
Strategem.__index = Strategem

function Strategem.new(strategem_name, target_index)
    local conditions = L{
        StrategemCountCondition.new(1, Condition.Operator.GreaterThanOrEqualTo)
    }

    local self = setmetatable(JobAbility.new(0, 0, 0, strategem_name, nil, conditions), Strategem)
    return self
end

function Strategem:get_strategem_name()
    return self:get_job_ability_name()
end

function Strategem:gettype()
    return "strategemaction"
end

function Strategem:getrawdata()
    local res = {}

    res.strategem = {}
    res.strategem.x = self.x
    res.strategem.y = self.y
    res.strategem.z = self.z
    res.strategem.command = self:get_command()

    return res
end

function Strategem:copy()
    return Strategem.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_strategem_name())
end

function Strategem:is_equal(action)
    if action == nil then return false end

    return self:gettype() == action:gettype() and self:get_strategem_name() == action:get_strategem_name()
end

function Strategem:tostring()
    return "Strategem: %s":format(self:get_strategem_name())
end

return Strategem