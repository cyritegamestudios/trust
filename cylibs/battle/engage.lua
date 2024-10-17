---------------------------
-- Action representing engaging a target.
-- @class module
-- @name Engage

local serializer_util = require('cylibs/util/serializer_util')
local SwitchTargetAction = require('cylibs/actions/switch_target')

local Engage = {}
Engage.__index = Engage
Engage.__type = "Engage"
Engage.__class = "Engage"

-------
<<<<<<< HEAD
-- Default initializer for a new engage.
=======
-- Default initializer for a new run to.
>>>>>>> main
-- @treturn Engage An engage action.
function Engage.new(conditions)
    local self = setmetatable({}, Engage)
    self.conditions = conditions or L{}
    return self
end

function Engage:destroy()
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function Engage:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-------
-- Returns the list of conditions for turning around.
-- @treturn list List of conditions
function Engage:get_conditions()
    return self.conditions
end

-------
-- Returns the maximum range in yalms.
-- @treturn number Range in yalms
function Engage:get_range()
    return 30
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function Engage:get_name()
    return 'Engage'
end

-------
-- Return the Action to use this action on a target.
-- @treturn Action Action to use ability
function Engage:to_action(target_index, _)
    return SequenceAction.new(L{
        SwitchTargetAction.new(target_index, 3),
    }, self.__class..'_target_and_engage')
end

function Engage:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end)
    return "Engage.new(" .. serializer_util.serialize_args(conditions_to_serialize) .. ")"
end

function Engage:__eq(otherItem)
    if otherItem.__type == self.__type then
        return true
    end
    return false
end

return Engage