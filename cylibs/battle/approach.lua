---------------------------
-- Action representing approach engaging in battle.
-- @class module
-- @name Approach

local SwitchTargetAction = require('cylibs/actions/switch_target')

local Approach = {}
Approach.__index = Approach
Approach.__class = "Approach"

-------
-- Default initializer for a new approach.
-- @treturn Approach An approach
function Approach.new()
    local self = setmetatable({}, Approach)
    self.conditions = L{
        MaxDistanceCondition.new(30)
    }
    return self
end

function Approach:destroy()
end

-------
-- Returns the list of conditions for approaching.
-- @treturn list List of conditions
function Approach:get_conditions()
    return self.conditions
end

-------
-- Returns the maximum approach range in yalms.
-- @treturn number Range in yalms
function Approach:get_range()
    return 30
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function Approach:get_name()
    return 'Approach'
end

-------
-- Return the Action to use this job ability on a target.
-- @treturn Action Action to cast the spell
function Approach:to_action(target_index)
    return SequenceAction.new(L{
        RunToAction.new(target_index, 3, true),
        SwitchTargetAction.new(target_index, 3)
    }, self.__class..'_approach')
end

function Approach:serialize()
    return "Approach.new()"
end

return Approach