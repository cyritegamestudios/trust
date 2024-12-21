---------------------------
-- Action representing a waltz
-- @class module
-- @name Waltz

local Event = require('cylibs/events/Luvent')

local JobAbility = require('cylibs/actions/job_ability')
local Waltz = setmetatable({}, {__index = JobAbility })
Waltz.__index = Waltz
Waltz.__class = "Waltz"

-- Called when a status removal has no effect
function Waltz:on_status_removal_no_effect()
    return self.status_removal_no_effect
end

-- Called when a status effect is removed successfully
function Waltz:on_status_removed()
    return self.status_removed
end

function Waltz.new(waltz_name, target_index)
    local conditions = L{
        NotCondition.new(L{ HasBuffCondition.new('Saber Dance', windower.ffxi.get_player().index) }, windower.ffxi.get_player().index),
        MinTacticalPointsCondition.new(res.job_abilities:with('en', waltz_name).tp_cost),
    }
    local self = setmetatable(JobAbility.new(0, 0, 0, waltz_name, target_index, conditions), Waltz)

    self.status_removal_no_effect = Event.newEvent()
    self.status_removed = Event.newEvent()

    return self
end

function Waltz:destroy()
    Action.destroy(self)

    self.status_removal_no_effect:removeAllActions()
    self.status_removed:removeAllActions()
end

function Waltz:gettype()
    return "waltzaction"
end

function Waltz:debug_string()
    return "Waltz: %s":format(self:get_job_ability_name())
end

return Waltz