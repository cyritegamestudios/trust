---------------------------
-- Condition checking whether the player or party member is the party leader.
-- @class module
-- @name PartyLeaderCondition

local Condition = require('cylibs/conditions/condition')
local PartyLeaderCondition = setmetatable({}, { __index = Condition })
PartyLeaderCondition.__index = PartyLeaderCondition
PartyLeaderCondition.__class = "PartyLeaderCondition"
PartyLeaderCondition.__type = "PartyLeaderCondition"

function PartyLeaderCondition.new(target_index)
    local self = setmetatable(Condition.new(target_index), PartyLeaderCondition)
    return self
end

function PartyLeaderCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party = player.party
        if party then
            local party_leader_id = party:get_party_leader_id()
            if party_leader_id then
                return party_leader_id == target.id
            end
        end
    end
    return false
end

function PartyLeaderCondition:tostring()
    return "Is party leader"
end

function PartyLeaderCondition.description()
    return "Is party leader."
end

function PartyLeaderCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function PartyLeaderCondition:serialize()
    return "PartyLeaderCondition.new()"
end

function PartyLeaderCondition:__eq(otherItem)
    return otherItem.__class == PartyLeaderCondition.__class
end

return PartyLeaderCondition