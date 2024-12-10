---------------------------
-- Action representing a waltz
-- @class module
-- @name Waltz

local JobAbility = require('cylibs/actions/job_ability')
local Waltz = setmetatable({}, {__index = JobAbility })
Waltz.__index = Waltz
Waltz.__class = "Waltz"

function Waltz.new(waltz_name, target_index)
    local conditions = L{
        NotCondition.new(L{ HasBuffCondition.new('Saber Dance', windower.ffxi.get_player().index) }, windower.ffxi.get_player().index)
    }
    local self = setmetatable(JobAbility.new(0, 0, 0, waltz_name, target_index, conditions), Waltz)
    return self
end

function Waltz:gettype()
    return "waltzaction"
end

function Waltz:debug_string()
    return "Waltz: %s":format(self:get_job_ability_name())
end

return Waltz