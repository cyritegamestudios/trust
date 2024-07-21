---------------------------
-- Condition checking whether the target is in battle.
-- @class module
-- @name InBattleCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')

local InBattleCondition = setmetatable({}, { __index = Condition })
InBattleCondition.__index = InBattleCondition
InBattleCondition.__type = "InBattleCondition"
InBattleCondition.__class = "InBattleCondition"

function InBattleCondition.new()
    local self = setmetatable(Condition.new(), InBattleCondition)
    return self
end

function InBattleCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return target.status == 1
    end
    return false
end

function InBattleCondition:tostring()
    return "Is in battle"
end

function InBattleCondition.description()
    return "Is in battle."
end

function InBattleCondition:serialize()
    return "InBattleCondition.new(" .. serializer_util.serialize_args() .. ")"
end

function InBattleCondition:__eq(otherItem)
    return otherItem.__class == InBattleCondition.__class
end

return InBattleCondition




