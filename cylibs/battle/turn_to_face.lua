---------------------------
-- Action representing facing a target.
-- @class module
-- @name TurnAround

local serializer_util = require('cylibs/util/serializer_util')

local TurnToFace = {}
TurnToFace.__index = TurnToFace
TurnToFace.__class = "TurnToFace"

-------
-- Default initializer for a new turn to face.
-- @treturn TurnToFace A turn around.
function TurnToFace.new(conditions)
    local self = setmetatable({}, TurnToFace)
    self.conditions = conditions or L{}
    return self
end

function TurnToFace:destroy()
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function TurnToFace:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-------
-- Returns the list of conditions for turning around.
-- @treturn list List of conditions
function TurnToFace:get_conditions()
    return self.conditions
end

-------
-- Returns the maximum range in yalms.
-- @treturn number Range in yalms
function TurnToFace:get_range()
    return 999
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function TurnToFace:get_name()
    return 'Turn to Face'
end

-------
-- Returns the localized name for the action.
-- @treturn string Localized name
function TurnToFace:get_localized_name()
    return 'Turn to Face'
end

-------
-- Return the Action to use this action on a target.
-- @treturn Action Action to use ability
function TurnToFace:to_action(target_index, _)
    return SequenceAction.new(L{
        BlockAction.new(function() player_util.face(windower.ffxi.get_mob_by_index(target_index)) end, "face target"),
    }, self.__class..'_turn_to_face')
end

function TurnToFace:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end)
    return "TurnToFace.new(" .. serializer_util.serialize_args(conditions_to_serialize) .. ")"
end

function TurnToFace:is_valid()
    return true
end

function TurnToFace:__eq(otherItem)
    if otherItem.__type == self.__type then
        return true
    end
    return false
end

return TurnToFace