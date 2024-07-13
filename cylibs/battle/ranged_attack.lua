---------------------------
-- Action representing a ranged attack in battle.
-- @class module
-- @name RangedAttack

local serializer_util = require('cylibs/util/serializer_util')
local RangedAttackAction = require('cylibs/actions/ranged_attack')

local RangedAttack = {}
RangedAttack.__index = RangedAttack
RangedAttack.__class = "RangedAttack"

-------
-- Default initializer for a new ranged attack.
-- @treturn RangedAttack A ranged attack.
function RangedAttack.new(conditions)
    local self = setmetatable({}, RangedAttack)
    self.conditions = conditions or L{}

    self:add_condition(MaxDistanceCondition.new(20))

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
    return 20
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function RangedAttack:get_name()
    return 'Ranged Attack'
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
    local conditions_classes_to_serialize = L{
        InBattleCondition.__class,
        IdleCondition.__class,
        HasBuffCondition.__class,
        HasBuffsCondition.__class,
        MaxHitPointsPercentCondition.__class,
        MinHitPointsPercentCondition.__class,
        MinManaPointsPercentCondition.__class,
        MinManaPointsCondition.__class,
        MinTacticalPointsCondition.__class,
        NotCondition.__class
    }
    local conditions_to_serialize = self.conditions:filter(function(condition) return conditions_classes_to_serialize:contains(condition.__class)  end)
    return "RangedAttack.new(" .. serializer_util.serialize_args(conditions_to_serialize) .. ")"
end

return RangedAttack