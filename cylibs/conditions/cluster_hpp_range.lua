---------------------------
-- Condition checking whether min_hpp <= target's hpp <= max_hpp for a cluster of party members.
-- @class module
-- @name ClusterHitPointsPercentRangeCondition
local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local ClusterHitPointsPercentRangeCondition = setmetatable({}, { __index = Condition })
ClusterHitPointsPercentRangeCondition.__index = ClusterHitPointsPercentRangeCondition
ClusterHitPointsPercentRangeCondition.__class = "ClusterHitPointsPercentRangeCondition"
ClusterHitPointsPercentRangeCondition.__type = "ClusterHitPointsPercentRangeCondition"

function ClusterHitPointsPercentRangeCondition.new(min_hpp, max_hpp, num_party_members, include_alliance, target_index)
    local self = setmetatable(Condition.new(target_index), ClusterHitPointsPercentRangeCondition)
    self.min_hpp = min_hpp or 1
    self.max_hpp = max_hpp or 100
    self.num_party_members = num_party_members or 3
    self.include_alliance = include_alliance
    return self
end

function ClusterHitPointsPercentRangeCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party_member = player.alliance:get_alliance_member_named(target.name)
        if party_member then
            local conditions = L{
                HitPointsPercentRangeCondition.new(self.min_hpp, self.max_hpp)
            }
            local party_members
            if self.include_alliance then
                party_members = player.alliance:get_alliance_members(false, 21):filter(function(alliance_member)
                    return alliance_member:is_valid() and Condition.check_conditions(conditions, alliance_member:get_mob().index)
                end)
            else
                party_members = player.party:get_party_members(true, 21):filter(function(alliance_member)
                    return alliance_member:is_valid() and Condition.check_conditions(conditions, alliance_member:get_mob().index)
                end)
            end
            if party_members:length() >= self.num_party_members then
                local cluster = party_members:filter(function(other_party_member)
                    local distance = geometry_util.distance(party_member:get_mob(), other_party_member:get_mob())
                    return distance < 10
                end)
                return cluster:length() >= self.num_party_members
            end
        end
    end
    return false
end

function ClusterHitPointsPercentRangeCondition:get_config_items()
    return L{
        ConfigItem.new('num_party_members', 1, 6, 1, function(value) return value.."" end, "Num Party Members"),
        ConfigItem.new('min_hpp', 0, 100, 1, function(value) return value.." %" end, "Min HP %"),
        ConfigItem.new('max_hpp', 0, 100, 1, function(value) return value.." %" end, "Max HP %"),
        BooleanConfigItem.new('include_alliance', 'Include Alliance'),
    }
end

function ClusterHitPointsPercentRangeCondition:tostring()
    if self.include_alliance then
        return string.format("%d alliance members with HP >= %d%% and HP <= %d%%", self.num_party_members, self.min_hpp, self.max_hpp)
    else
        return string.format("%d party members with HP >= %d%% and HP <= %d%%", self.num_party_members, self.min_hpp, self.max_hpp)
    end
end

function ClusterHitPointsPercentRangeCondition.description()
    return "Party HP >= X% and HP <= Y%"
end

function ClusterHitPointsPercentRangeCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function ClusterHitPointsPercentRangeCondition:serialize()
    return "ClusterHitPointsPercentRangeCondition.new(" .. serializer_util.serialize_args(self.min_hpp, self.max_hpp, self.num_party_members, self.include_alliance) .. ")"
end

return ClusterHitPointsPercentRangeCondition




