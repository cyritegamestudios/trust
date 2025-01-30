---------------------------
-- Action representing a ranged attack in battle.
-- @class module
-- @name RangedAttack

local serializer_util = require('cylibs/util/serializer_util')
local RangedAttackAction = require('cylibs/actions/ranged_attack')

local RangedAttack = {}
RangedAttack.__index = RangedAttack
RangedAttack.__class = "RangedAttack"
RangedAttack.__type = "RangedAttack"

-------
-- Default initializer for a new ranged attack.
-- @treturn RangedAttack A ranged attack.
function RangedAttack.new(conditions)
    local self = setmetatable({}, RangedAttack)
    self.conditions = conditions or L{}

    local matches = (conditions or L{}):filter(function(c)
        return c.__class == MaxDistanceCondition.__class
    end)
    if matches:length() == 0 then
        self:add_condition(MaxDistanceCondition.new(20))
    end

    return self
end

function RangedAttack:destroy()
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function RangedAttack:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-------
-- Returns the list of conditions for ranged attacking.
-- @treturn list List of conditions
function RangedAttack:get_conditions()
    return self.conditions
end

-------
-- Returns the maximum range in yalms.
-- @treturn number Range in yalms
function RangedAttack:get_range()
    return 24
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function RangedAttack:get_name()
    return 'Ranged Attack'
end

function RangedAttack:get_localized_name()
    return self:get_name()
end

-------
-- Return the Action to use this action on a target.
-- @treturn Action Action to use ability
function RangedAttack:to_action(target_index, player)
    return SequenceAction.new(L{
        BlockAction.new(function() player_util.face(windower.ffxi.get_mob_by_index(target_index))  end, "face target"),
        WaitAction.new(0, 0, 0, 0.5),
        RangedAttackAction.new(target_index, player)
    }, self.__class..'_ranged_attack')
end

function RangedAttack:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition) return conditions_classes_to_serialize:contains(condition.__class)  end)
    return "RangedAttack.new(" .. serializer_util.serialize_args(conditions_to_serialize) .. ")"
end

function RangedAttack:is_valid()
    return true
end

function RangedAttack:__eq(otherItem)
    if otherItem.__type == self.__type then
        return true
    end
    return false
end

return RangedAttack