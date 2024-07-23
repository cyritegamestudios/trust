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

-------
-- Default initializer for a condition.
-- @tparam number target_index (optional) Target index, will override target_index passed into is_satisfied
-- @treturn Condition A condition
function Condition.new(target_index)
    local self = setmetatable({
        target_index = target_index;
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

function Condition.defaultSerializableConditionClasses()
    return L{
        InBattleCondition.__class,
        IdleCondition.__class,
        HasBuffCondition.__class,
        HasBuffsCondition.__class,
        HasRunesCondition.__class,
        MainJobCondition.__class,
        MaxDistanceCondition.__class,
        MaxHitPointsPercentCondition.__class,
        MinHitPointsPercentCondition.__class,
        MinManaPointsCondition.__class,
        MinManaPointsPercentCondition.__class,
        MaxManaPointsPercentCondition.__class,
        MinManaPointsCondition.__class,
        MinTacticalPointsCondition.__class,
        ModeCondition.__class,
        NotCondition.__class,
        ZoneCondition.__class,
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



