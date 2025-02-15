---------------------------
-- Action representing running to a target.
-- @class module
-- @name RunTo

local serializer_util = require('cylibs/util/serializer_util')

local RunTo = {}
RunTo.__index = RunTo
RunTo.__type = "RunTo"
RunTo.__class = "RunTo"

-------
-- Default initializer for a new run to.
-- @treturn RunTo A run to.
function RunTo.new(distance, conditions)
    local self = setmetatable({}, RunTo)
    self.distance = distance or 3
    self.conditions = conditions or L{}
    return self
end

function RunTo:destroy()
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function RunTo:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-------
-- Returns the list of conditions for turning around.
-- @treturn list List of conditions
function RunTo:get_conditions()
    return self.conditions
end

-------
-- Returns the maximum range in yalms.
-- @treturn number Range in yalms
function RunTo:get_range()
    return 999
end

-------
-- Returns the distance to run to in yalms.
-- @treturn number Distance in yalms
function RunTo:get_distance()
    return self.distance
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function RunTo:get_name()
    return 'Run To'
end

-------
-- Returns the localized name for the action.
-- @treturn string Localized name
function RunTo:get_localized_name()
    return 'Run To'
end

-------
-- Returns the display name.
-- @treturn string Display name
function RunTo:get_display_name()
    return string.format("Run %d yalms from target", self.distance)
end

-------
-- Returns the config items that will be used when creating the config editor
-- to edit this ability.
-- @treturn list List of ConfigItem
function RunTo:get_config_items()
    return L{
        ConfigItem.new('distance', 3, 30, 1, function(value) return value.." yalms" end, "Distance from Target"),
    }
end

-------
-- Return the Action to use this action on a target.
-- @treturn Action Action to use ability
function RunTo:to_action(target_index, _)
    return SequenceAction.new(L{
        BlockAction.new(function() player_util.face(windower.ffxi.get_mob_by_index(target_index))  end),
        RunToAction.new(target_index, self.distance),
        WaitAction.new(0, 0, 0, 1.5),
    }, self.__class..'_run_to')
end

function RunTo:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end)
    return "RunTo.new(" .. serializer_util.serialize_args(self.distance, conditions_to_serialize) .. ")"
end

function RunTo:copy()
    local conditions = L{}
    for condition in self:get_conditions():it() do
        conditions:append(condition:copy())
    end
    return RunTo.new(self.distance, conditions)
end

function RunTo:__eq(otherItem)
    if otherItem.__type == self.__type and otherItem:get_name() == self:get_name()
        and otherItem:get_distance() == self:get_distance() then
        return true
    end
    return false
end

function RunTo:is_valid()
    return true
end

return RunTo