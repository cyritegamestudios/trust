---------------------------
-- Condition checking whether the player is in the mog house.
-- @class module
-- @name InMogHouseCondition

local Condition = require('cylibs/conditions/condition')
local InMogHouseCondition = setmetatable({}, { __index = Condition })
InMogHouseCondition.__index = InMogHouseCondition

function InMogHouseCondition.new()
    local self = setmetatable(Condition.new(), InMogHouseCondition)
    return self
end

function InMogHouseCondition:is_satisfied(target_index)
    return windower.ffxi.get_info().mog_house
end

function InMogHouseCondition:is_player_only()
    return true
end

function InMogHouseCondition:tostring()
    return "InMogHouseCondition"
end

function InMogHouseCondition:serialize()
    return "InMogHouseCondition.new()"
end

return InMogHouseCondition




