---------------------------
-- Action representing a ranged attack in battle.
-- @class module
-- @name RangedAttack

local RangedAttackAction = require('cylibs/actions/ranged_attack')

local RangedAttack = {}
RangedAttack.__index = RangedAttack
RangedAttack.__class = "RangedAttack"

-------
-- Default initializer for a new ranged attack.
-- @treturn RangedAttack A ranged attack.
function RangedAttack.new()
    local self = setmetatable({}, RangedAttack)
    self.conditions = L{
        MaxDistanceCondition.new(20)
    }
    return self
end

function RangedAttack:destroy()
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

return RangedAttack