---------------------------
-- Condition checking whether the target is targeted by the party, optionally including the alliance.
-- @class module
-- @name PartyTargetedCondition

local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local PartyTargetedCondition = setmetatable({}, { __index = Condition })
PartyTargetedCondition.__index = PartyTargetedCondition
PartyTargetedCondition.__type = "PartyTargetedCondition"
PartyTargetedCondition.__class = "PartyTargetedCondition"

function PartyTargetedCondition.new(include_alliance)
    local self = setmetatable(Condition.new(), PartyTargetedCondition)
    self.include_alliance = include_alliance
    return self
end

function PartyTargetedCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        if self.include_alliance then
            local alliance = player.alliance
            if alliance then
                local party_target_indices = S(alliance:get_alliance_members(false):map(function(p)
                    return p:get_target_index()
                end))
                return party_target_indices:contains(target.index)
            end
        else
            local party = player.party
            if party then
                local party_target_indices = S(party:get_party_members(true):map(function(p)
                    return p:get_target_index()
                end))
                return party_target_indices:contains(target.index)
            end
        end
    end
end

function PartyTargetedCondition:get_config_items()
    return L{
        BooleanConfigItem.new('include_alliance', 'Include Alliance')
    }
end

function PartyTargetedCondition:tostring()
    if self.include_alliance then
        return "Target is targeted by alliance"
    else
        return "Target is targeted by party"
    end
end

function PartyTargetedCondition.description()
    return "Target is targeted by party or alliance."
end

function PartyTargetedCondition.valid_targets()
    return S{ Condition.TargetType.Enemy }
end

function PartyTargetedCondition:__eq(otherItem)
    return otherItem.__class == PartyTargetedCondition.__class
            and self.include_alliance == otherItem.include_alliance
end

function PartyTargetedCondition:serialize()
    return "PartyTargetedCondition.new(" .. serializer_util.serialize_args(self.include_alliance) .. ")"
end

return PartyTargetedCondition




