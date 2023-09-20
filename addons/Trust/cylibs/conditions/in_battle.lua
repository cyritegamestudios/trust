---------------------------
-- Condition checking whether the player is in battle.
-- @class module
-- @name InBattleCondition

local Condition = require('cylibs/conditions/condition')

local InBattleCondition = setmetatable({}, { __index = Condition })
InBattleCondition.__index = InBattleCondition
InBattleCondition.__type = "InBattleCondition"

function InBattleCondition.new()
    local self = setmetatable(Condition.new(), InBattleCondition)
    return self
end

function InBattleCondition.decode(rawSettings)
    return InBattleCondition.new()
end

function InBattleCondition:encode()
    local settings = {}
    settings.type = InBattleCondition.__type
    return settings
end

function InBattleCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return target.status == 1
    end
    return false
end

function InBattleCondition:tostring()
    return "InBattleCondition"
end

return InBattleCondition




