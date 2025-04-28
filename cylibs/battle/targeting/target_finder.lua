local MobFilter = require('cylibs/battle/monsters/mob_filter')

local TargetFinder = {}
TargetFinder.__index = TargetFinder

function TargetFinder.new(party, alliance, mob_filter, target_names)
    local self = setmetatable({}, TargetFinder)

    self.party = party
    self.alliance = alliance
    self.mob_filter = mob_filter
    self.target_names = target_names

    return self
end

function TargetFinder:get_next_target(target_id_blacklist)
    target_id_blacklist = target_id_blacklist or L{}

    local current_target = self.alliance:get_target_by_index(self.party:get_player():get_target_index())
    if current_target and not target_id_blacklist:contains(current_target:get_id()) and self:is_valid_target(current_target:get_mob())
            and Condition.check_conditions(L{ AggroedCondition.new() }, current_target:get_mob().index) then
        return Monster.new(current_target:get_id())
    end
    local all_targets = self:get_all_targets():filter(function(target)
        return not target_id_blacklist:contains(target.id) and self:is_valid_target(target)
    end)
    if all_targets:length() > 0 then
        if state.PullActionMode.value == 'Target' or self.max_num_targets > 1 then
            return Monster.new(all_targets:random().id)
        else
            return Monster.new(all_targets[1].id)
        end
    else
        return nil
    end
end

function TargetFinder:get_all_targets()
    local all_targets = L{}
    if state.AutoPullMode.value == 'Aggroed' then
        -- 1. Aggroed mobs that are unclaimed and not targeted by party members
        -- 2. Aggroed mobs that are unclaimed
        -- 3. Aggroed mobs that are party claimed
        all_targets = self.mob_filter:get_aggroed_mobs(L{ UnclaimedCondition.new(), NotCondition.new(L{ PartyTargetedCondition.new() }) })
                + self.mob_filter:get_aggroed_mobs(L{ MobFilter.Type.Unclaimed })
                + self.mob_filter:get_aggroed_mobs(L{ MobFilter.Type.PartyClaimed })
    elseif state.AutoPullMode.value == 'Auto' then
        -- 1. Aggroed mobs that are party claimed
        -- 2. Aggroed mobs that are unclaimed
        -- 3. Unaggroed mobs in target name whitelist
        all_targets = self.mob_filter:get_aggroed_mobs(L{ MobFilter.Type.PartyClaimed })
                + self.mob_filter:get_aggroed_mobs(L{ MobFilter.Type.Unclaimed })
                + (self.mob_filter:get_nearby_mobs(L{ MobFilter.Type.Unclaimed }):filter(function(mob)
            return self.target_names:contains(mob.name)
        end))
    elseif state.AutoPullMode.value == 'All' then
        -- 1. All mobs that are party claimed
        -- 2. All mobs that are unclaimed
        all_targets = self.mob_filter:get_nearby_mobs(L{ MobFilter.Type.PartyClaimed })
                + self.mob_filter:get_nearby_mobs(L{ MobFilter.Type.Unclaimed })
    end
    return all_targets
end

return TargetFinder