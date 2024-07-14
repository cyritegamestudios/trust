---------------------------
-- Condition that always returns false.
-- @class module
-- @name NeverCondition

local Condition = require('cylibs/conditions/condition')
local NeverCondition = setmetatable({}, { __index = Condition })
NeverCondition.__index = NeverCondition
NeverCondition.__class = "NeverCondition"
NeverCondition.__type = "NeverCondition"

function NeverCondition.new()
    local self = setmetatable(Condition.new(windower.ffxi.get_player().index), NeverCondition)
    return self
end

function NeverCondition:is_satisfied(_)
    return false
end

function NeverCondition:get_config_items()
    return L{}
end

function NeverCondition:tostring()
    return "Never"
end

function NeverCondition:serialize()
    return "NeverCondition.new()"
end

function NeverCondition:__eq(otherItem)
    return otherItem.__class == NeverCondition.__class
end

return NeverCondition