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
local TargetNamesCondition = require('cylibs/conditions/target_names')
local UnclaimedCondition = require('cylibs/conditions/unclaimed')
local ffxi_util = require('cylibs/util/ffxi_util')

-- The mob array snapshot is shared via ffxi_util.get_mob_snapshot(): one
-- scan per gambit pass instead of one per filter call.

MobFilter.Type = {}
MobFilter.Type.All = L{}
MobFilter.Type.Aggroed = L{ AggroedCondition.new() }
MobFilter.Type.Unclaimed = L{ UnclaimedCondition.new() }
MobFilter.Type.PartyClaimed = L{ PartyClaimedCondition.new(true) }

function MobFilter.new(alliance, max_distance, default_sort, blacklist)
    local self = setmetatable({}, MobFilter)
    self.alliance = alliance
    self.max_distance = max_distance or 25
    self.center_position = nil
    self.default_sort = default_sort or function(mob1, mob2)
        return mob1.distance < mob2.distance
    end
    self.blacklist = blacklist or L{}
    self.default_conditions = nil
    self.default_conditions_time = 0
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

    -- filter() returns a new list, so the shared snapshot is never mutated,
    -- and the sort below only ever sorts the filtered copy.
    local mobs = ffxi_util.get_mob_snapshot():filter(function(mob)
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
-- The set only depends on this filter's construction parameters, so it is
-- built once and reused for a tenth of a second at a time (the same window
-- as the mob snapshot) instead of being rebuilt on every call. The window
-- bounds how stale the captured alliance member ids can be. Callers never
-- mutate the returned list: get_nearby_mobs concatenates it into a new one.
-- @treturn list Default conditions
function MobFilter:get_default_conditions()
    if self.default_conditions == nil or (os.clock() - self.default_conditions_time) >= 0.1 then
        self.default_conditions = L{
            ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()),
            MinHitPointsPercentCondition.new(1),
            MaxDistanceCondition.new(self.max_distance, nil, self.center_position),
            MaxHeightDistanceCondition.new(8, Condition.Operator.LessThanOrEqualTo),
            ConditionalCondition.new(L{ ClaimedCondition.new(self.alliance:get_alliance_member_ids()), UnclaimedCondition.new() }, Condition.LogicalOperator.Or),
            NotCondition.new(L{ TargetNamesCondition.new(self.blacklist) }),
        }
        self.default_conditions_time = os.clock()
    end
    return self.default_conditions
end

-------
-- Sets the center position to calculate mob distance from. Defaults to player position if nil.
-- @tparam vector center_position Position
function MobFilter:set_center_position(center_position)
    self.center_position = center_position
    self.default_conditions = nil
end

-------
-- Returns the center position to calculate mob distance from.
-- @treturn vector Center position.
function MobFilter:get_center_position()
    return self.center_position
end

return MobFilter

