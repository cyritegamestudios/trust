---------------------------
-- Condition checking whether the target is claimed by the party, optionally including the alliance.
-- @class module
-- @name PartyClaimedCondition

local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local PartyClaimedCondition = setmetatable({}, { __index = Condition })
PartyClaimedCondition.__index = PartyClaimedCondition
PartyClaimedCondition.__type = "PartyClaimedCondition"
PartyClaimedCondition.__class = "PartyClaimedCondition"

function PartyClaimedCondition.new(include_alliance)
    local self = setmetatable(Condition.new(), PartyClaimedCondition)
    self.include_alliance = include_alliance
    return self
end

function PartyClaimedCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        if self.include_alliance then
            local alliance = player.alliance
            if alliance then
                return alliance:get_alliance_member_ids():contains(target.claim_id)
            end
        else
            local party = player.party
            if party then
                return party:get_party_member_ids():contains(target.claim_id)
            end
        end
    end
    return false
end

function PartyClaimedCondition:get_config_items()
    return L{
        BooleanConfigItem.new('include_alliance', 'Include Alliance')
    }
end

function PartyClaimedCondition:tostring()
    if self.include_alliance then
        return "Target is claimed by alliance"
    else
        return "Target is claimed by party"
    end
end

function PartyClaimedCondition.description()
    return "Target is claimed by party or alliance."
end

function PartyClaimedCondition.valid_targets()
    return S{ Condition.TargetType.Enemy }
end

function PartyClaimedCondition:__eq(otherItem)
    return otherItem.__class == PartyClaimedCondition.__class
            and self.include_alliance == otherItem.include_alliance
end

function PartyClaimedCondition:serialize()
    return "PartyClaimedCondition.new(" .. serializer_util.serialize_args(self.include_alliance) .. ")"
end

return PartyClaimedCondition




