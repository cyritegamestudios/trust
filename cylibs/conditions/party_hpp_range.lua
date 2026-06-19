---------------------------
-- Condition checking whether at least num_party_members party (or alliance) members have HPP in [min_hpp, max_hpp].
-- @class module
-- @name PartyHppRangeCondition
local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local PartyHppRangeCondition = setmetatable({}, { __index = Condition })
PartyHppRangeCondition.__index = PartyHppRangeCondition
PartyHppRangeCondition.__class = "PartyHppRangeCondition"
PartyHppRangeCondition.__type = "PartyHppRangeCondition"

function PartyHppRangeCondition.new(min_hpp, max_hpp, num_party_members, include_alliance, target_index)
    local self = setmetatable(Condition.new(target_index), PartyHppRangeCondition)
    self.min_hpp = min_hpp or 50
    self.max_hpp = max_hpp or 100
    self.num_party_members = num_party_members or 6
    self.include_alliance = include_alliance
    return self
end

function PartyHppRangeCondition:is_satisfied(target_index)
    local conditions = L{
        HitPointsPercentRangeCondition.new(self.min_hpp, self.max_hpp)
    }
    local members
    if self.include_alliance then
        members = player.alliance:get_alliance_members(false, 21)
    else
        members = player.party:get_party_members(true, 21)
    end
    local matching = members:filter(function(member)
        return member:is_valid() and Condition.check_conditions(conditions, member:get_mob().index)
    end)
    return matching:length() >= math.min(self.num_party_members, members:length())
end

function PartyHppRangeCondition:get_config_items()
    return L{
        ConfigItem.new('num_party_members', 1, 6, 1, function(value) return value.."" end, "Num Party Members"),
        ConfigItem.new('min_hpp', 0, 100, 1, function(value) return value.." %" end, "Min HP %"),
        ConfigItem.new('max_hpp', 0, 100, 1, function(value) return value.." %" end, "Max HP %"),
        BooleanConfigItem.new('include_alliance', 'Include Alliance'),
    }
end

function PartyHppRangeCondition:tostring()
    if self.include_alliance then
        return string.format("%d alliance members with HP >= %d%% and HP <= %d%%", self.num_party_members, self.min_hpp, self.max_hpp)
    else
        return string.format("%d party members with HP >= %d%% and HP <= %d%%", self.num_party_members, self.min_hpp, self.max_hpp)
    end
end

function PartyHppRangeCondition.description()
    return "Party members with HP in range."
end

function PartyHppRangeCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function PartyHppRangeCondition:serialize()
    return "PartyHppRangeCondition.new(" .. serializer_util.serialize_args(self.min_hpp, self.max_hpp, self.num_party_members, self.include_alliance) .. ")"
end

return PartyHppRangeCondition
