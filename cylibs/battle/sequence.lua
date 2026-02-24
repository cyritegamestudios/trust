---------------------------
-- Action representing a sequence of abilities.
-- @class module
-- @name Sequence

local serializer_util = require('cylibs/util/serializer_util')
local SequenceAction = require('cylibs/actions/sequence')

local Sequence = {}
Sequence.__index = Sequence
Sequence.__class = "Sequence"
Sequence.__type = "Sequence"

-------
-- Default initializer for a new sequence.
-- @tparam abilities List of abilities
-- @tparam conditions List of conditions
-- @treturn Sequence A sequence of abilities.
function Sequence.new(abilities, conditions)
    local self = setmetatable({}, Sequence)

    self.abilities = abilities
    self.conditions = conditions or L{}

    return self
end

function Sequence:destroy()
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function Sequence:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-------
-- Returns the list of conditions..
-- @treturn list List of conditions
function Sequence:get_conditions()
    local conditions = self.conditions
    for ability in self.abilities:it() do
        conditions = conditions + ability:get_conditions()
    end
    return conditions
end

-------
-- Returns the maximum range in yalms.
-- @treturn number Range in yalms
function Sequence:get_range()
    return self.abilities:map(function(ability) return ability:get_range() end):sort()[1]
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function Sequence:get_name()
    return 'Sequence'
end

-------
-- Returns the localized name for the action.
-- @treturn string Localized action name
function Sequence:get_localized_name()
    return self:get_name()
end

-------
-- Returns the ability id for the action.
-- @treturn string Ability id
function Sequence:get_ability_id()
    local ability_id = 'sequence'
    for ability in self.abilities:it() do
        ability_id = string.format("%s%s", ability_id, ability:get_ability_id())
    end
    return ability_id
end

-------
-- Return the Action to use this action on a target.
-- @treturn Action Action to use ability
function Sequence:to_action(target_index, player)
    return SequenceAction.new(self.abilities:map(function(ability)
        return ability:to_action(target_index, player)
    end), self.__class..'_sequence')
end

function Sequence:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition) return conditions_classes_to_serialize:contains(condition.__class)  end)
    return "Sequence.new(" .. serializer_util.serialize_args(self.abilities, conditions_to_serialize) .. ")"
end

function Sequence:is_valid()
    return true
end

function Sequence:__eq(otherItem)
    if otherItem.__type == self.__type then
        return true
    end
    return false
end

return Sequence