---------------------------
-- Filters nearby mobs.
-- @class module
-- @name MobFilter

local MobFilter = {}
MobFilter.__index = MobFilter
MobFilter.__class = "MobFilter"

local ClaimedCondition = require('cylibs/conditions/claimed')
local ConditionalCondition = require('cylibs/conditions/conditional')
local MaxHeightDistanceCondition = require('cylibs/conditions/max_height_distance')
local UnclaimedCondition = require('cylibs/conditions/unclaimed')

MobFilter.Type = {}
MobFilter.Type.All = "All"
MobFilter.Type.Aggroed = "Aggroed"
MobFilter.Type.Unclaimed = "Unclaimed"
MobFilter.Type.PartyClaimed = "PartyClaimed"
MobFilter.Type.PartyTargeted = "PartyTargeted"
MobFilter.Type.NotPartyTargeted = "NotPartyTargeted"

function MobFilter.new(alliance, max_distance, default_sort)
    local self = setmetatable({}, MobFilter)
    self.alliance = alliance
    self.max_distance = max_distance or 25
    self.default_sort = default_sort or function(mob1, mob2)
        return mob1.distance < mob2.distance
    end
    return self
end

function MobFilter:destroy()
end

-------
-- Returns nearby mobs.
-- @tparam list filter (optional) List of MobFilter filters
-- @treturn list List of mobs
function MobFilter:get_nearby_mobs(filter_types)
    local filters = (filter_types or L{ MobFilter.Type.All }):map(function(filter_type)
        return self:get_filter_for_type(filter_type)
    end)

    local mobs = L{}
    for _, mob in pairs(windower.ffxi.get_mob_array()) do
        mobs:append(mob)
    end

    local conditions = L{
        ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()),
        MinHitPointsPercentCondition.new(1),
        MaxDistanceCondition.new(50),
        MaxHeightDistanceCondition.new(8, Condition.Operator.LessThanOrEqualTo),
        ConditionalCondition.new(L{ ClaimedCondition.new(self.alliance:get_alliance_member_ids()), UnclaimedCondition.new() }, Condition.LogicalOperator.Or)
    }

    mobs = mobs:filter(function(mob)
        if not Condition.check_conditions(conditions, mob.index) or mob.spawn_type ~= 16 then
            return false
        end
        for filter in filters:it() do
            if not filter(mob) then
                return false
            end
        end
        return true
    end)

    return mobs:sort(self.default_sort)
end

-------
-- Returns the a list of aggroed mobs.
-- @treturn list List of aggroed mob metadata
function MobFilter:get_aggroed_mobs(filter_types)
    return self:get_nearby_mobs(L{ MobFilter.Type.Aggroed } + (filter_types or L{}))
end

-------
-- Returns the filter function for a filter type.
-- @tparam MobFilter.Type filter_type Filter type
-- @treturn function Filter function
function MobFilter:get_filter_for_type(filter_type)
    local filter_for_type = {}
    filter_for_type[MobFilter.Type.All] = function(_)
        return true
    end
    filter_for_type[MobFilter.Type.Aggroed] = function(mob)
        return mob.status == 1
    end
    filter_for_type[MobFilter.Type.Unclaimed] = function(mob)
        return mob.claim_id == 0 or mob.claim_id == nil
    end
    filter_for_type[MobFilter.Type.PartyClaimed] = function(mob)
        if mob.claim_id then
            return self.alliance:get_alliance_member_ids():contains(mob.claim_id)
        end
        return false
    end
    filter_for_type[MobFilter.Type.PartyTargeted] = function(mob)
        local party_target_indices = S(self.alliance:get_alliance_members(false):map(function(p)
            return p:get_target_index()
        end))
        return party_target_indices:contains(mob.index)
    end
    filter_for_type[MobFilter.Type.NotPartyTargeted] = function(mob)
        local party_target_indices = S(self.alliance:get_alliance_members(false):map(function(p)
            return p:get_target_index()
        end))
        return not party_target_indices:contains(mob.index)
    end
    return filter_for_type[filter_type]
end

return MobFilter

