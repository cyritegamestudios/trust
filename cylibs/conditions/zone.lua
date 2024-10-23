---------------------------
-- Condition checking whether the player is in any of the given zones.
-- @class module
-- @name ZoneCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local GroupConfigItem = require('ui/settings/editors/config/GroupConfigItem')
local localization_util = require('cylibs/util/localization_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local ZoneCondition = setmetatable({}, { __index = Condition })
ZoneCondition.__index = ZoneCondition
ZoneCondition.__type = "ZoneCondition"
ZoneCondition.__class = "ZoneCondition"

function ZoneCondition.new(zone_ids)
    local self = setmetatable(Condition.new(), ZoneCondition)
    self.zone_ids = zone_ids or L{ windower.ffxi.get_info().zone }
    return self
end

function ZoneCondition:is_satisfied(target_index)
    local current_zone_id = windower.ffxi.get_info().zone
    return self.zone_ids:contains(current_zone_id)
end

function ZoneCondition:get_config_items()
    local all_zone_ids = L{}
    for i = 1, 299 do
        if res.zones[i] then
            all_zone_ids:append(res.zones[i].en)
        end
    end
    all_zone_ids:sort()
    all_zone_ids = all_zone_ids:map(function(zone_name) return res.zones:with('en', zone_name).id  end)
    return L{
        GroupConfigItem.new('zone_ids', L{
            PickerConfigItem.new('zone_id_1', self.zone_ids[1] or windower.ffxi.get_info().zone, all_zone_ids, function(zone_id)
                return res.zones[zone_id].en
            end, "Zone 1"),
        }, nil, "In Zone"),
    }
end

function ZoneCondition:tostring()
    return "In "..localization_util.commas(L(self.zone_ids):map(function(zone_id) return res.zones[zone_id].en end))
end

function ZoneCondition.description()
    return "In a zone."
end

function ZoneCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function ZoneCondition:serialize()
    return "ZoneCondition.new(" .. serializer_util.serialize_args(self.zone_ids) .. ")"
end

return ZoneCondition




