---------------------------
-- Action representing approach engaging in battle.
-- @class module
-- @name Approach

local ClaimedCondition = require('cylibs/conditions/claimed')
local FollowAction = require('cylibs/actions/follow')
local serializer_util = require('cylibs/util/serializer_util')
local EngageAction = require('cylibs/actions/engage')

local Approach = {}
Approach.__index = Approach
Approach.__class = "Approach"

-------
-- Default initializer for a new approach.
-- @treturn Approach An approach
function Approach.new(conditions)
    local self = setmetatable({}, Approach)
    self.conditions = conditions or L{}

    local matches = (conditions or L{}):filter(function(c)
        return c.__class == MaxDistanceCondition.__class
    end)
    if matches:length() == 0 then
        self:add_condition(MaxDistanceCondition.new(50))
    end

    return self
end

function Approach:destroy()
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function Approach:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
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
    return 50
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function Approach:get_name()
    return 'Approach'
end

function Approach:get_localized_name()
    return self:get_name()
end

function Approach:get_ability_id()
    return "Approach"
end

-------
-- Return the Action to use this job ability on a target.
-- @treturn Action Action to cast the spell
function Approach:to_action(target_index)
    local actions = L{}

    local target = windower.ffxi.get_mob_by_index(target_index)
    if target and target.distance:sqrt() > 25 then
       actions:append(RunToAction.new(target_index, 25))
    end

    actions:append(WaitAction.new(0, 0, 0, 2))
    actions:append(EngageAction.new(target_index))
    actions:append(FollowAction.new(target_index, L{ ClaimedCondition.new() }))

    local action = SequenceAction.new(actions, self.__class..'_approach')

    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        action.display_name = 'Approaching → '..target.name
    end

    return action
end

function Approach:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition) return conditions_classes_to_serialize:contains(condition.__class)  end)
    return "Approach.new(" .. serializer_util.serialize_args(conditions_to_serialize) .. ")"
end

function Approach:is_valid()
    return true
end

function Approach:__eq(otherItem)
    if otherItem.__type == self.__type then
        return true
    end
    return false
end

return Approach