---------------------------
-- Filters nearby mobs.
-- @class module
-- @name MobFilter

local MobFilter = {}
MobFilter.__index = MobFilter
MobFilter.__class = "MobFilter"

local AggroedCondition = require('cylibs/conditions/aggroed')
local ClaimedCondition = require('cylibs/conditions/claimed')
local ConditionalCondition = require('cylibs/conditions/conditional')
local MaxHeightDistanceCondition = require('cylibs/conditions/max_height_distance')
local PartyClaimedCondition = require('cylibs/conditions/party_claimed')
local UnclaimedCondition = require('cylibs/conditions/unclaimed')

MobFilter.Type = {}
MobFilter.Type.All = L{}
MobFilter.Type.Aggroed = L{ AggroedCondition.new() }
MobFilter.Type.Unclaimed = L{ UnclaimedCondition.new() }
MobFilter.Type.PartyClaimed = L{ PartyClaimedCondition.new(true) }

function MobFilter.new(alliance, max_distance, default_sort)
    local self = setmetatable({}, MobFilter)
    self.alliance = alliance
    self.max_distance = max_distance or 25
    self.center_position = nil
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
function MobFilter:get_nearby_mobs(conditions)
    local all_conditions = L{}
    for condition in conditions:it() do
        if class(condition) == 'List' then
            all_conditions = all_conditions + condition
        else
            all_conditions:append(condition)
        end
    end
    conditions = all_conditions

    conditions = self:get_default_conditions() + conditions

    local mobs = L{}
    for _, mob in pairs(windower.ffxi.get_mob_array()) do
        mobs:append(mob)
    end
    mobs = mobs:filter(function(mob)
        if mob.spawn_type ~= 16 then
            return false
        end
        return Condition.check_conditions(conditions, mob.index)
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
-- Returns the default conditions to use in every mob filter.
-- @treturn list Default conditions
function MobFilter:get_default_conditions()
    return L{
        ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()),
        MinHitPointsPercentCondition.new(1),
        MaxDistanceCondition.new(self.max_distance, nil, self.center_position),
        MaxHeightDistanceCondition.new(8, Condition.Operator.LessThanOrEqualTo),
        ConditionalCondition.new(L{ ClaimedCondition.new(self.alliance:get_alliance_member_ids()), UnclaimedCondition.new() }, Condition.LogicalOperator.Or)
    }
end

-------
-- Sets the center position to calculate mob distance from. Defaults to player position if nil.
-- @tparam vector center_position Position
function MobFilter:set_center_position(center_position)
    self.center_position = center_position
end

-------
-- Returns the center position to calculate mob distance from.
-- @treturn vector Center position.
function MobFilter:get_center_position()
    return self.center_position
end

return MobFilter

