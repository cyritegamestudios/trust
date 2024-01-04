---------------------------
-- Condition checking whether the player is in any of the given zones.
-- @class module
-- @name ZoneCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local ZoneCondition = setmetatable({}, { __index = Condition })
ZoneCondition.__index = ZoneCondition

function ZoneCondition.new(zone_ids)
    local self = setmetatable(Condition.new(), ZoneCondition)
    self.zone_ids = zone_ids or S{}
    return self
end

function ZoneCondition:is_satisfied(target_index)
    local current_zone_id = windower.ffxi.get_info().zone
    return self.zone_ids:contains(current_zone_id)
end

function ZoneCondition:tostring()
    return "ZoneCondition"
end

function ZoneCondition:serialize()
    return "ZoneCondition.new(" .. serializer_util.serialize_args(self.zone_ids) .. ")"
end

return ZoneCondition




