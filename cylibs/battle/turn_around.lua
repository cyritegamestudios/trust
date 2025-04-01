---------------------------
-- Action representing turning around in battle.
-- @class module
-- @name TurnAround

local serializer_util = require('cylibs/util/serializer_util')

local TurnAround = {}
TurnAround.__index = TurnAround
TurnAround.__class = "TurnAround"

-------
-- Default initializer for a new turn around.
-- @treturn TurnAround A turn around.
function TurnAround.new(conditions)
    local self = setmetatable({}, TurnAround)
    self.conditions = conditions or L{}
    return self
end

function TurnAround:destroy()
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function TurnAround:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-------
-- Returns the list of conditions for turning around.
-- @treturn list List of conditions
function TurnAround:get_conditions()
    return self.conditions
end

-------
-- Returns the maximum range in yalms.
-- @treturn number Range in yalms
function TurnAround:get_range()
    return 999
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function TurnAround:get_name()
    return 'Turn Around'
end

-------
-- Returns the localized name for the action.
-- @treturn string Localized name
function TurnAround:get_localized_name()
    return 'Turn Around'
end

-------
-- Return the Action to use this action on a target.
-- @treturn Action Action to use ability
function TurnAround:to_action(target_index, _)
    local target = windower.ffxi.get_mob_by_index(target_index)
    return SequenceAction.new(L{
        BlockAction.new(function()
            handle_set('AutoFaceMobMode', 'Away')
            player_util.face_away(target)
        end, "set_face_away", self:get_localized_name()),
    }, self.__class..'_turn_around')
end

function TurnAround:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end)
    return "TurnAround.new(" .. serializer_util.serialize_args(conditions_to_serialize) .. ")"
end

function TurnAround:is_valid()
    return true
end

function TurnAround:__eq(otherItem)
    if otherItem.__type == self.__type then
        return true
    end
    return false
end

return TurnAround