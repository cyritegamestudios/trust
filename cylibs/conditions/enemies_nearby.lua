---------------------------
-- Condition checking whether a certain number of enemies are nearby and claimed.
-- @class module
-- @name EnemiesNearbyCondition
local MobFilter = require('cylibs/battle/monsters/mob_filter')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')
local StatusAilment = require('cylibs/battle/status_ailment')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local Condition = require('cylibs/conditions/condition')
local EnemiesNearbyCondition = setmetatable({}, { __index = Condition })
EnemiesNearbyCondition.__index = EnemiesNearbyCondition
EnemiesNearbyCondition.__class = "EnemiesNearbyCondition"
EnemiesNearbyCondition.__type = "EnemiesNearbyCondition"

function EnemiesNearbyCondition.new(num_required, distance, operator, debuff_names, regex)
    local self = setmetatable(Condition.new(), EnemiesNearbyCondition)
    self.num_required = num_required or 4
    self.distance = distance or 12
    self.debuff_names = debuff_names or L{}
    self.regex = regex or ''
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function EnemiesNearbyCondition:is_satisfied(_)
    local mob_filter = MobFilter.new(player.alliance, self.distance)

    if self.regex:length() > 0 then
        local nearby_mobs = mob_filter:get_nearby_mobs(MobFilter.Type.All)
        for target in nearby_mobs:it() do
            if target.name:match(self.regex) ~= nil then
                return false
            end
        end
    end

    local targets = mob_filter:get_aggroed_mobs()
    if self.debuff_names:length() > 0 then
        targets = targets:filter(function(mob)
            local monster = player.alliance:get_target_by_index(mob.index)
            if monster then
                local debuff_ids = self.debuff_names:map(function(debuff_name)
                    return buff_util.buff_id(debuff_name)
                end)
                return not monster:has_any_debuff(debuff_ids)
            end
            return false
        end)
    end
    return self:eval(targets:length(), self.num_required, self.operator)
end

function EnemiesNearbyCondition:get_config_items()
    local all_debuffs = L(S(L(buff_util.get_all_debuff_ids()):map(function(debuff_id)
        if res.buffs[debuff_id] then
            return res.buffs[debuff_id].en
        end
        return nil
    end):compact_map()))
    return L{
        ConfigItem.new('num_required', 1, 30, 1, function(value) return value.."" end, "Number of Enemies"),
        ConfigItem.new('distance', 1, 30, 1, function(value) return value.." yalms" end, "Distance from Player"),
        MultiPickerConfigItem.new('debuff_names', self.debuff_names, all_debuffs, function(debuff_names)
            if debuff_names:length() == 0 then
                return 'None'
            end
            local text = localization_util.commas(debuff_names:map(function(debuff_name) return StatusAilment.new(debuff_name):get_localized_name() end))
            return text
        end, "Not Afflicted With"),
        TextInputConfigItem.new('regex', self.regex or '', 'Blacklist Pattern', function(_) return true end, 225),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function EnemiesNearbyCondition:tostring()
    local description
    if self.num_required == 1 then
        description = self.operator.." "..self.num_required.." enemy within "..self.distance.." yalms"
    else
        description = self.operator.." "..self.num_required.." enemies within "..self.distance.." yalms"
    end
    if self.debuff_names:length() > 0 then
        description = string.format("%s not afflicted with %s", description, localization_util.commas(self.debuff_names, 'or'))
    end
    if self.regex:length() > 0 then
        description = string.format("%s and name not matching %s", description, self.regex)
    end
    return description
end

function EnemiesNearbyCondition.description()
    return "Number of enemies nearby."
end

function EnemiesNearbyCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function EnemiesNearbyCondition:serialize()
    return "EnemiesNearbyCondition.new(" .. serializer_util.serialize_args(self.num_required, self.distance, self.operator, self.debuff_names, self.regex) .. ")"
end

function EnemiesNearbyCondition:__eq(otherItem)
    return otherItem.__class == EnemiesNearbyCondition.__class
            and self.num_required == otherItem.num_required
            and self.distance == otherItem.distance
            and self.debuff_names == otherItem.debuff_names
            and self.regex == otherItem.regex
            and self.operator == otherItem.operator
end

return EnemiesNearbyCondition