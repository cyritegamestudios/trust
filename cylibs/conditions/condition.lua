---------------------------
-- Condition base class.
-- @class module
-- @name Condition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = {}
Condition.__index = Condition
Condition.__class = "Condition"

Condition.Operator = {}
Condition.Operator.Equals = "=="
Condition.Operator.GreaterThan = ">"
Condition.Operator.GreaterThanOrEqualTo = ">="
Condition.Operator.LessThan = "<"
Condition.Operator.LessThanOrEqualTo = "<="

Condition.LogicalOperator = {}
Condition.LogicalOperator.And = "and"
Condition.LogicalOperator.Or = "or"

Condition.TargetType = {}
Condition.TargetType.Self = "Self"
Condition.TargetType.Ally = "Ally"
Condition.TargetType.Enemy = "Enemy"
Condition.TargetType.AllTargets = S{ Condition.TargetType.Self, Condition.TargetType.Ally, Condition.TargetType.Enemy }

-------
-- Default initializer for a condition.
-- @tparam number target_index (optional) Target index, will override target_index passed into is_satisfied
-- @treturn Condition A condition
function Condition.new(target_index)
    local self = setmetatable({
        target_index = target_index;
        editable = true;
    }, Condition)

    return self
end

function Condition:destroy()
end

function Condition:is_satisfied(target_index)
    return true
end

function Condition:eval(arg1, arg2, operator)
    if operator == Condition.Operator.Equals then
        return arg1 == arg2
    elseif operator == Condition.Operator.GreaterThan then
        return arg1 > arg2
    elseif operator == Condition.Operator.GreaterThanOrEqualTo then
        return arg1 >= arg2
    elseif operator == Condition.Operator.LessThan then
        return arg1 < arg2
    elseif operator == Condition.Operator.LessThanOrEqualTo then
        return arg1 <= arg2
    else
        return false
    end
end

function Condition:set_target_index(target_index)
    self.target_index = target_index
end

function Condition:get_target_index()
    return self.target_index
end

function Condition:tostring()
    return "condition"
end

function Condition:serialize()
    return "Condition.new(" .. serializer_util.serialize_args() .. ")"
end

function Condition:should_serialize()
    return Condition.defaultSerializableConditionClasses():contains(self.__class) and self:is_editable()
end

function Condition:is_editable()
    return self.editable
end

function Condition.defaultSerializableConditionClasses()
    return L {
        IdleCondition.__class,
        InBattleCondition.__class,
        GainDebuffCondition.__class,
        HasBuffsCondition.__class,
        HasDebuffCondition.__class,
        MaxHitPointsPercentCondition.__class,
        MinHitPointsPercentCondition.__class,
        HitPointsPercentRangeCondition.__class,
        MeleeAccuracyCondition.__class,
        MinManaPointsCondition.__class,
        MaxManaPointsPercentCondition.__class,
        MinManaPointsPercentCondition.__class,
        MaxTacticalPointsCondition.__class,
        MinTacticalPointsCondition.__class,
        MaxDistanceCondition.__class,
        HasBuffCondition.__class,
        ZoneCondition.__class,
        MainJobCondition.__class,
        SubJobCondition.__class,
        JobCondition.__class,
        ReadyAbilityCondition.__class,
        FinishAbilityCondition.__class,
        HasRunesCondition.__class,
        EnemiesNearbyCondition.__class,
        ModeCondition.__class,
        PetHitPointsPercentCondition.__class,
        PetTacticalPointsCondition.__class,
        HasPetCondition.__class,
        NumResistsCondition.__class,
        SkillchainPropertyCondition.__class,
        HasDazeCondition.__class,
        CombatSkillsCondition.__class,
        NotCondition.__class,
        StrategemCountCondition.__class,
        IsAlterEgoCondition.__class,
        ReadyChargesCondition.__class,
        ItemCountCondition.__class,
        SkillchainWindowCondition.__class,
        SkillchainStepCondition.__class,
        InTownCondition.__class,
        ZoneChangeCondition.__class,
        BeginCastCondition.__class,
        HasCumulativeMagicEffectCondition.__class,
        StatusCondition.__class,
    }
end

function Condition.check_conditions(conditions, param, ...)
    for condition in conditions:it() do
        local target_index = condition:get_target_index()
        if target_index == nil then
            target_index = param
        end
        if not condition:is_satisfied(target_index, ...) then
            logger.error(condition.__class, "Failed", condition:tostring())
            return false
        end
    end
    return true
end

function Condition.valid_targets()
    return Condition.TargetType.AllTargets
end

function Condition:copy()
    local original = self
    local lookup_table = {}

    local function _copy(original)
        if type(original) ~= "table" then
            return original
        elseif lookup_table[original] then
            return lookup_table[original]
        end
        local new_table = {}
        lookup_table[original] = new_table
        for key, value in pairs(original) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(original))
    end

    return _copy(original)
end

return Condition



