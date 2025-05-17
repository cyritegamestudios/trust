---------------------------
-- Action representing engaging a target.
-- @class module
-- @name Target

local serializer_util = require('cylibs/util/serializer_util')
local EngageAction = require('cylibs/actions/engage')

local Target = {}
Target.__index = Target
Target.__type = "Target"
Target.__class = "Target"

-------
-- Default initializer for a new engage.
-- @treturn Engage An engage action.
function Target.new(conditions)
    local self = setmetatable({}, Target)
    self.conditions = conditions or L{}
    return self
end

function Target:destroy()
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function Target:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-------
-- Returns the list of conditions for turning around.
-- @treturn list List of conditions
function Target:get_conditions()
    return self.conditions
end

-------
-- Returns the maximum range in yalms.
-- @treturn number Range in yalms
function Target:get_range()
    return 30
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function Target:get_name()
    return 'Target'
end

-------
-- Returns the localized name for the action.
-- @treturn string Localized name
function Target:get_localized_name()
    return 'Target'
end

-------
-- Return the Action to use this action on a target.
-- @treturn Action Action to use ability
function Target:to_action(target_index, _)
    return SequenceAction.new(L{
        EngageAction.new(target_index, true),
        BlockAction.new(function()
            player_util.face(windower.ffxi.get_mob_by_index(target_index))
        end)
    }, self.__class..'_target_and_engage')
end

function Target:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end)
    return "Target.new(" .. serializer_util.serialize_args(conditions_to_serialize) .. ")"
end

function Target:is_valid()
    return true
end

function Target:__eq(otherItem)
    if otherItem.__type == self.__type then
        return true
    end
    return false
end

return Target