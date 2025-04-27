---------------------------
-- Action representing disengaging a target.
-- @class module
-- @name Disengage

local serializer_util = require('cylibs/util/serializer_util')
local DisengageAction = require('cylibs/actions/disengage')

local Disengage = {}
Disengage.__index = Disengage
Disengage.__type = "Disengage"
Disengage.__class = "Disengage"

-------
-- Default initializer for a new disengage.
-- @treturn Disengage A disengage action.
function Disengage.new(conditions)
    local self = setmetatable({}, Disengage)
    self.conditions = conditions or L{}
    return self
end

function Disengage:destroy()
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function Disengage:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-------
-- Returns the list of conditions for turning around.
-- @treturn list List of conditions
function Disengage:get_conditions()
    return self.conditions
end

-------
-- Returns the maximum range in yalms.
-- @treturn number Range in yalms
function Disengage:get_range()
    return 30
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function Disengage:get_name()
    return 'Disengage'
end

-------
-- Returns the localized name for the action.
-- @treturn string Localized name
function Disengage:get_localized_name()
    return 'Disengage'
end

-------
-- Return the Action to use this action on a target.
-- @treturn Action Action to use ability
function Disengage:to_action(target_index, _)
    return SequenceAction.new(L{
        DisengageAction.new(),
    }, self.__class..'_disengage')
end

function Disengage:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end)
    return "Disengage.new(" .. serializer_util.serialize_args(conditions_to_serialize) .. ")"
end

function Disengage:is_valid()
    return true
end

function Disengage:__eq(otherItem)
    if otherItem.__type == self.__type then
        return true
    end
    return false
end

return Disengage