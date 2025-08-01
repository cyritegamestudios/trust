local AggroedCondition = require('cylibs/conditions/aggroed')
local Approach = require('cylibs/battle/approach')
local ClaimedCondition = require('cylibs/conditions/claimed')
local ConditionalCondition = require('cylibs/conditions/conditional')
local DisposeBag = require('cylibs/events/dispose_bag')
local Engage = require('cylibs/battle/engage')
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')
local MobFilter = require('cylibs/battle/monsters/mob_filter')
local PartyClaimedCondition = require('cylibs/conditions/party_claimed')
local PartyLeaderCondition = require('cylibs/conditions/party_leader')
local PartyMemberCountCondition = require('cylibs/conditions/party_member_count')
local PartyTargetedCondition = require('cylibs/conditions/party_targeted')
local RunToLocationAction = require('cylibs/actions/runtolocation')
local TargetNamesCondition = require('cylibs/conditions/target_names')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Puller = setmetatable({}, {__index = Gambiter })
Puller.__index = Puller
Puller.__class = "Puller"

state.AutoPullMode = M{['description'] = 'Pull Monsters to Fight', 'Off', 'Auto','Aggroed','All'}
state.AutoPullMode:set_description('Auto', "Pull monsters for the party from the target list.")
state.AutoPullMode:set_description('Aggroed', "Pull any monster aggressive to the party.")
state.AutoPullMode:set_description('All', "Pull any monster that's nearby.")

state.AutoCampMode = M{['description'] = 'Return to Camp after Battle', 'Off', 'Auto'}
state.AutoCampMode:set_description('Auto', "Return to camp after battle (set with // trust pull camp).")

state.PullActionMode = M{['description'] = 'Pull Actions', 'Auto', 'Target', 'Approach'}
state.PullActionMode:set_description('Auto', "Pull with pull actions in settings.")
state.PullActionMode:set_description('Target', "Pull by targeting and engaging.")
state.PullActionMode:set_description('Approach', "Pull by engaging and approaching.")


function Puller.new(action_queue, pull_settings, job)
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, state.AutoPullMode), Puller)

    self.job = job
    self.dispose_bag = DisposeBag.new()

    self:set_pull_settings(pull_settings)

    return self
end

function Puller:destroy()
    Gambiter.destroy(self)

    self.dispose_bag:destroy()
end

function Puller:on_add()
    Gambiter.on_add(self)

    local current_target = self:get_alliance():get_target_by_index(self:get_party():get_player():get_target_index())
    if state.AutoPullMode.value ~= 'Off' and current_target and self:is_valid_target(current_target:get_mob()) then
        self:set_pull_target(Monster.new(current_target.id))
    end

    local on_pull_mode_changed = function(new_value)
        self:get_party():set_should_ignore_assist_target(new_value ~= 'Off')
        if new_value ~= 'Off' then
            self:set_pull_settings(self.pull_settings)
            windower.send_command('input /autotarget off')
            self:get_party():set_assist_target(self:get_party():get_player())
        else
            self:get_party():set_party_target_index(self:get_party():get_assist_target():get_target_index())
        end
    end
    on_pull_mode_changed(state.AutoPullMode.value)

    self.dispose_bag:add(state.AutoPullMode:on_state_change():addAction(function(_, new_value)
        on_pull_mode_changed(new_value)
    end), state.AutoPullMode:on_state_change())

    self.dispose_bag:add(WindowerEvents.MobKO:addAction(function(mob_id, mob_name, status)
        if self:get_target() and self:get_target():get_id() == mob_id then
            logger.notice(self.__class, 'mob_ko', mob_name, self:get_target():get_mob().hpp, status)
            self:set_pull_target(nil) -- this is necessary otherwise get_target() returns valid until next loop
            self:check_target(L{ mob_id })
        end
    end), WindowerEvents.MobKO)
end

function Puller:tic(_, _)
    if state.AutoPullMode.value == 'Off' then
        return
    end

    logger.notice(self.__class, 'tic', 'target_index', self.target_index or 'none')

    self:return_to_camp()
    self:check_target()
end

function Puller:target_change(target_index)
    Gambiter.target_change(self, target_index)

    self:check_gambits(nil, nil, true)
end

function Puller:check_target(target_id_blacklist)
    if state.AutoPullMode.value == 'Off' then
        return
    end

    local next_target = self:get_pull_target()
    if not self:is_valid_target(next_target and next_target:get_mob(), target_id_blacklist) then
        if next_target and next_target:get_mob() then
            local previous_target = next_target:get_mob()
            logger.notice(self.__class, 'check_target', 'clear', previous_target.name, previous_target.hpp, previous_target.index, previous_target.status, previous_target.claim_id or 'unclaimed')
        end

        next_target = self:get_next_target(target_id_blacklist)
        if next_target then
            self:set_pull_target(next_target)
            logger.notice(self.__class, 'check_target', 'set_pull_target', next_target:get_name(), next_target:get_mob().index)
        else
            self:set_pull_target(nil)
            logger.notice(self.__class, 'check_target', 'no valid targets')
            if state.AutoPullMode.value == 'Auto' then
                self:get_party():add_to_chat(self:get_party():get_player(), "I can't find anything to pull. I'll check again soon.", self.__class..'_no_valid_targets', 15)
            end
            self:return_to_camp()
            return
        end
    end
end

function Puller:get_all_targets()
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

function Puller:get_next_target(target_id_blacklist)
    target_id_blacklist = target_id_blacklist or L{}

    local current_target = self:get_alliance():get_target_by_index(self:get_party():get_player():get_target_index())
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

function Puller:is_valid_target(target, target_id_blacklist)
    if not target or target_id_blacklist and target_id_blacklist:contains(target.id) then
        return false
    end

    local pull_abilities = self.pull_abilities[state.PullActionMode.value]

    local max_pull_ability_range = 0
    for gambit in pull_abilities:it() do
        max_pull_ability_range = math.max(max_pull_ability_range, gambit:getAbility():get_range())
    end
    max_pull_ability_range = math.min(max_pull_ability_range, self.distance)

    local conditions = L{
        MinHitPointsPercentCondition.new(1),
        ConditionalCondition.new(L{
            PartyClaimedCondition.new(true),
            ConditionalCondition.new(L{ UnclaimedCondition.new(), MaxDistanceCondition.new(max_pull_ability_range) }, Condition.LogicalOperator.And)
        }, Condition.LogicalOperator.Or),
    }
    return not L{ 2, 3 }:contains(target.status) and Condition.check_conditions(conditions, target.index)
end

function Puller:get_pull_target()
    return self:get_target()
end

function Puller:set_pull_target(target)
    if state.AutoPullMode.value == 'Off' then
        self:get_party():set_party_target_index(self:get_party():get_assist_target():get_target_index())
    else
        self:get_party():set_party_target_index(target and target:get_mob().index)
    end
end

function Puller:get_pull_settings()
    return self.pull_settings
end

function Puller:set_pull_settings(pull_settings)
    self.pull_settings = pull_settings
    self.distance = pull_settings.Distance
    self.mob_filter = MobFilter.new(self:get_alliance(), self.distance or 25)
    if pull_settings.RandomizeTarget then
        self.max_num_targets = 6
    else
        self.max_num_targets = 1
    end
    self:set_target_names(pull_settings.Targets or L{})

    for gambit in pull_settings.Gambits:it() do
        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = L{
            GambitCondition.new(ModeCondition.new('PullActionMode', 'Auto'), GambitTarget.TargetType.Self)
        } + self:get_default_conditions(gambit)
        for condition in conditions:it() do
            condition:set_editable(false)
            gambit:addCondition(condition)
        end
    end

    local approach = Gambit.new(GambitTarget.TargetType.Enemy, L{}, Approach.new(L{MaxDistanceCondition.new(35)}), GambitTarget.TargetType.Enemy, L{"Pulling"})
    approach.conditions = L{
        GambitCondition.new(ModeCondition.new('PullActionMode', 'Approach'), GambitTarget.TargetType.Self)
    } + self:get_default_conditions(approach)

    local auto_target = Gambit.new(GambitTarget.TargetType.Enemy, L{}, Engage.new(L{MaxDistanceCondition.new(30)}), GambitTarget.TargetType.Enemy, L{"Pulling","Reaction"})
    auto_target.conditions = L{
        GambitCondition.new(ModeCondition.new('PullActionMode', 'Target'), GambitTarget.TargetType.Self),
    } + self:get_default_conditions(auto_target)

    self.pull_abilities = {
        Auto = pull_settings.Gambits,
        Approach = L{ approach },
        Target = L{ auto_target },
    }

    local gambit_settings = {
        Gambits = self.pull_abilities.Auto + self.pull_abilities.Approach + self.pull_abilities.Target
    }
    
    self:set_gambit_settings(gambit_settings)
end

function Puller:get_default_conditions(gambit)
    local conditions = L{
        GambitCondition.new(UnclaimedCondition.new(), GambitTarget.TargetType.Enemy),
        GambitCondition.new(MaxDistanceCondition.new(gambit:getAbility():get_range()), GambitTarget.TargetType.Enemy),
        GambitCondition.new(MinHitPointsPercentCondition.new(1), GambitTarget.TargetType.Enemy),
        GambitCondition.new(NotCondition.new(L{ HasBuffCondition.new('weakness') }), GambitTarget.TargetType.Self),
    }
    if state.AutoPullMode.value == 'Aggroed' then
        conditions:append(GambitCondition.new(AggroedCondition.new(), GambitTarget.TargetType.Enemy))
    elseif state.AutoPullMode.value == 'Auto' then
        conditions:append(GambitCondition.new(TargetNamesCondition.new(self:get_target_names()), GambitTarget.TargetType.Enemy))
    end
    local alter_ego_conditions = L{
        -- FIXME: lower party member count condition from 6
        GambitCondition.new(ConditionalCondition.new(
            L{
                NotCondition.new(L{ PartyLeaderCondition.new() }),
                ModeCondition.new('AutoTrustsMode', 'Off'),
                ConditionalCondition.new(L{ ModeCondition.new('AutoTrustsMode', 'Auto'), ModeCondition.new('AutoPullMode', 'Auto'), PartyMemberCountCondition.new(6, Condition.Operator.GreaterThanOrEqualTo) }, Condition.LogicalOperator.And)
            },
            Condition.LogicalOperator.Or), GambitTarget.TargetType.Self)
    }
    return (alter_ego_conditions + conditions + self.job:get_conditions_for_ability(gambit:getAbility())):map(function(condition)
        if condition.__type ~= GambitCondition.__type then
            return GambitCondition.new(condition, GambitTarget.TargetType.Self)
        end
        return condition
    end)
end

function Puller:get_type()
    return "puller"
end

function Puller:set_target_names(target_names)
    self.target_names = target_names
end

function Puller:get_target_names()
    return self.target_names
end

function Puller:set_camp_position(position)
    self.mob_filter:set_center_position(position)
end

function Puller:get_camp_position()
    return self.mob_filter:get_center_position()
end

function Puller:get_cooldown()
    return 5
end

function Puller:allows_duplicates()
    return false
end

function Puller:allows_multiple_actions()
    return false
end

function Puller:return_to_camp()
    if state.AutoCampMode.value == 'Off' or self:get_pull_target() ~= nil
            or self:get_party():get_player():get_status() == 'Engaged' or self:get_camp_position() == nil then
        return false
    end

    local distance = self:get_party():get_player():distance(self:get_camp_position()[1], self:get_camp_position()[2])
    if distance > 40 then
        self:set_camp_position(nil)
        self:get_party():add_to_chat(self:get_party():get_player(), "I'm too far from camp to go back now.")
        return false
    end

    if distance > 2 then
        local return_to_camp_action = RunToLocationAction.new(self:get_camp_position()[1], self:get_camp_position()[2], self:get_camp_position()[3], 2.0)
        return_to_camp_action.identifier = "Return to camp"

        self.action_queue:push_action(return_to_camp_action, true)
    end

    return true
end

return Puller