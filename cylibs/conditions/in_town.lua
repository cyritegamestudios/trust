---------------------------
-- Condition checking whether the player is in a town.
-- @class module
-- @name InTownCondition

local zone_util = require('cylibs/util/zone_util')

local Condition = require('cylibs/conditions/condition')
local InTownCondition = setmetatable({}, { __index = Condition })
InTownCondition.__index = InTownCondition
InTownCondition.__type = "InTownCondition"
InTownCondition.__class = "InTownCondition"

function InTownCondition.new()
    local self = setmetatable(Condition.new(), InTownCondition)
    return self
end

function InTownCondition:is_satisfied(_)
    local info = windower.ffxi.get_info()
    if info then
        return zone_util.is_city(info.zone)
    end
    return false
end

function InTownCondition:get_config_items()
    return L{}
end

function InTownCondition:tostring()
    return "In town"
end

function InTownCondition.description()
    return "In town."
end

function InTownCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function InTownCondition:serialize()
    return "InTownCondition.new()"
end

return InTownCondition




