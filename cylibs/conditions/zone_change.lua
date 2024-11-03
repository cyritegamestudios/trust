---------------------------
-- Condition checking when a player changes zones.
-- @class module
-- @name ZoneChangeCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local ZoneChangeCondition = setmetatable({}, { __index = Condition })
ZoneChangeCondition.__index = ZoneChangeCondition
ZoneChangeCondition.__type = "ZoneChangeCondition"
ZoneChangeCondition.__class = "ZoneChangeCondition"

function ZoneChangeCondition.new(new_zone_id)
    local self = setmetatable(Condition.new(), ZoneChangeCondition)
    self.new_zone_id = new_zone_id or windower.ffxi.get_info().zone
    return self
end

function ZoneChangeCondition:is_satisfied(target_index, zone_id)
    return self.new_zone_id == zone_id
end

function ZoneChangeCondition:get_config_items()
    local all_zone_ids = L{}
    for i = 1, 299 do
        if res.zones[i] then
            all_zone_ids:append(res.zones[i].en)
        end
    end
    all_zone_ids:sort()
    all_zone_ids = all_zone_ids:map(function(zone_name) return res.zones:with('en', zone_name).id  end)
    return L{
        PickerConfigItem.new('new_zone_id', self.new_zone_id or windower.ffxi.get_info().zone, all_zone_ids, function(zone_id)
            return res.zones[zone_id].en
        end, "New Zone"),
    }
end

function ZoneChangeCondition:tostring()
    return "Zone change to "..res.zones[self.new_zone_id].en
end

function ZoneChangeCondition.description()
    return "Zone change."
end

function ZoneChangeCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function ZoneChangeCondition:serialize()
    return "ZoneChangeCondition.new(" .. serializer_util.serialize_args(self.new_zone_id) .. ")"
end

return ZoneChangeCondition




