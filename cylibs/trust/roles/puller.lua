local Approach = require('cylibs/battle/approach')
local ClaimedCondition = require('cylibs/conditions/claimed')
local DisposeBag = require('cylibs/events/dispose_bag')
local ffxi_util = require('cylibs/util/ffxi_util')
local RunToLocationAction = require('cylibs/actions/runtolocation')
local SwitchTargetAction = require('cylibs/actions/switch_target')

local Puller = setmetatable({}, {__index = Role })
Puller.__index = Puller
Puller.__class = "Puller"

state.AutoPullMode = M{['description'] = 'Pull Monsters to Fight', 'Off', 'Auto','Party','All'}
state.AutoPullMode:set_description('Off', "Okay, I won't pull monsters for the party.")
state.AutoPullMode:set_description('Auto', "Okay, I'll automatically pull monsters for the party.")
state.AutoPullMode:set_description('Party', "Okay, I'll pull monsters the party is fighting.")
state.AutoPullMode:set_description('All', "Okay, I'll pull any monster that's nearby.")

state.AutoCampMode = M{['description'] = 'Return to Camp after Battle', 'Off', 'Auto'}
state.AutoCampMode:set_description('Off', "Okay, I won't return to camp after battle.")
state.AutoCampMode:set_description('Auto', "Okay, I'll return to camp after battle (set camp with // trust pull camp).")

state.ApproachPullMode = M{['description'] = 'Force Pull with Approach', 'Off', 'Auto'}
state.ApproachPullMode:set_description('Auto', "Okay, I'll pull by engaging and approaching instead.")


function Puller.new(action_queue, target_names, pull_abilities, truster)
    local self = setmetatable(Role.new(action_queue), Puller)

    self.action_queue = action_queue
    self.target_names = target_names
    self.pull_abilities = pull_abilities
    self.pull_settings = {
        Abilities = pull_abilities
    }
    self.truster = truster
    self.last_pull_time = os.time() - 6
    self.dispose_bag = DisposeBag.new()

    return self
end

function Puller:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function Puller:on_add()
    Role.on_add(self)

    if state.AutoPullMode.value ~= 'Off' then
        windower.send_command('input /autotarget off')
    end

    self.dispose_bag:add(state.AutoPullMode:on_state_change():addAction(function(_, new_value)
        if new_value ~= 'Off' then
            windower.send_command('input /autotarget off')
            local assist_target = self:get_party():get_assist_target()
            if assist_target:get_id() ~= windower.ffxi.get_player().id then
                self:get_party():add_to_chat(self:get_party():get_player(), "I can't pull while I'm assisting someone else, so I'm going to stop assisting "..assist_target:get_name()..".")
                self:get_party():set_assist_target(self:get_party():get_player())
            end
        end
    end), state.AutoPullMode:on_state_change())

    if state.AutoTargetMode then
        self.dispose_bag:add(state.AutoTargetMode:on_state_change():addAction(function(_, new_value)
            if new_value ~= 'Off' and state.AutoPullMode.value ~= 'Off' then
                state.AutoPullMode:set('Off')
                self:get_party():add_to_chat(self:get_party():get_player(), "I can't pull while auto targeting, so I'm going to stop pulling.")
            end
        end), state.AutoTargetMode:on_state_change())
    end

    self.dispose_bag:add(WindowerEvents.MobKO:addAction(function(mob_id, mob_name)
        if self:get_pull_target() and self:get_pull_target():get_id() == mob_id then
            self:set_pull_target(nil)
            self:return_to_camp()
        end
    end), WindowerEvents.MobKO)
end

function Puller:return_to_camp()
    if state.AutoCampMode.value == 'Off' or self:get_camp_position() == nil then
        return
    end

    if ffxi_util.distance(ffxi_util.get_mob_position(windower.ffxi.get_player().name), self:get_camp_position()) > 40 then
        self:set_camp_position(nil)
        self:get_party():add_to_chat(self:get_party():get_player(), "I'm too far from camp to go back now.")
        return
    end

    local return_to_camp_action = RunToLocationAction.new(self:get_camp_position()[1], self:get_camp_position()[2], self:get_camp_position()[3], 2.0)
    return_to_camp_action.identifier = "Return to camp"

    self.action_queue:push_action(return_to_camp_action, true)
end

function Puller:target_change(target_index)
    Role.target_change(self, target_index)

    if state.AutoPullMode.value == 'Off' then
        return
    end

    local target = self:get_target()
    if target then
        if target == self:get_pull_target() then
            self:check_pull()
        end
    end
end

function Puller:tic(_, _)
    if state.AutoPullMode.value == 'Off' then
        return
    end

    logger.notice(self.__class, 'tic', 'target_index', self.target_index or 'none')

    self:check_target()
end

function Puller:check_target()
    local next_target = self:get_pull_target()
    if not self:is_valid_target(next_target) then
        self:set_pull_target(nil)

        next_target = self:get_next_target()
        if next_target then
            logger.notice(self.__class, 'check_target', 'set_pull_target', next_target:get_name(), next_target:get_mob().index)
            self:set_pull_target(next_target)
        else
            logger.notice(self.__class, 'check_target', 'no valid targets')
            self:get_party():add_to_chat(self:get_party():get_player(), "I can't find anything to pull. I'll check again soon.", self.__class..'_no_valid_targets', 15)
            return
        end
    end

    if next_target:is_claimed() and self:get_target() ~= next_target then
        logger.notice(self.__class, 'check_target', 'targeting', next_target:get_name(), next_target:get_mob().index)

        local target_action = SequenceAction.new(L{
            SwitchTargetAction.new(next_target:get_mob().index, 3),
        }, self.__class..'_set_target')
        target_action.priority = ActionPriority.highest

        self.action_queue:push_action(target_action, true)
    else
        self:check_pull()
    end
end

function Puller:check_pull()
    logger.notice(self.__class, 'check_pull', state.AutoPullMode.value)

    if os.time() - self.last_pull_time < 6 or self:get_pull_target() == nil
            or Condition.check_conditions(L{ ClaimedCondition.new(self:get_party():get_party_members(true):map(function(p) return p:get_id() end)) }, self:get_pull_target():get_mob().index)
            or (state.AutoTrustsMode.value ~= 'Off' and party_util.is_party_leader(windower.ffxi.get_player().id) and player.trust.main_job:role_with_type("truster"):get_valid_trusts():length() > 0) then
        return
    end
    self.last_pull_time = os.time()

    local next_target = self:get_pull_target()
    self:pull_target(next_target)
end

function Puller:get_next_target()
    if state.AutoPullMode.value == 'Party' then
        local party_targets = self:get_party():get_targets(function(t)
            return t:get_distance():sqrt() < 25 and t:get_mob().status == 1
        end):sort(function(t1, t2)
            return t1:get_distance() < t2:get_distance()
        end)
        if party_targets:length() > 0 then
            local party_target_indices = self:get_party():get_party_members(false):map(function(p)
                return p:get_target_index()
            end):compact_map()
            local next_target = party_targets:firstWhere(function(target)
                return target and not party_target_indices:contains(target:get_mob().index)
            end) or party_targets[1]
            local monster = Monster.new(next_target:get_id())
            return monster
        end
    else
        local target = ffxi_util.find_closest_mob(self:get_target_names(), L{}:extend(party_util.party_targets()), self.blacklist, self.pull_settings.Distance or 20)
        if target and target.distance:sqrt() < (self.pull_settings.Distance or 20) then
            local monster = Monster.new(target.id)
            return monster
        end
        local aggroed_mobs = ffxi_util.find_aggroed_mobs()
        if aggroed_mobs and aggroed_mobs:length() > 0 then
            logger.notice(self.__class, 'get_next_target', 'pulling aggroed mob')
            local monster = Monster.new(aggroed_mobs[1].id)
            return monster
        end
    end
    return nil
end

function Puller:pull_target(target)
    logger.notice(self.__class, 'pull_target', target:get_name(), target:get_mob().index, state.AutoPullMode.value)

    local ability = self:get_pull_abilities():firstWhere(function(ability)
        local conditions = L{}:extend(ability:get_conditions())
        conditions:append(MaxDistanceCondition.new(ability:get_range()))
        return Condition.check_conditions(conditions, target:get_mob().index)
    end)

    if ability then
        local pull_action = ability:to_action(target:get_mob().index, self:get_player())
        pull_action.priority = ActionPriority.highest
        pull_action.display_name = "Pulling → "..target.name

        self.action_queue:push_action(WaitAction.new(0, 0, 0, 1.5))
        self.action_queue:push_action(pull_action, true)
        self.action_queue:push_action(BlockAction.new(function() player_util.face(target:get_mob())  end, "face target"))
    else
        self:get_party():add_to_chat(self.party:get_player(), "I can't use any of my pull actions right now. Maybe we should add more?", "pull_action_cooldown", 10)
        self.action_queue:push_action(BlockAction.new(function() player_util.face(target:get_mob())  end, "face target"))
    end
end

function Puller:is_valid_target(target)
    if not target or not target:get_mob() then
        return false
    end
    local conditions = L{
        MaxDistanceCondition.new(self.pull_settings.Distance or 20),
        MinHitPointsPercentCondition.new(1),
        ClaimedCondition.new(L{ 0 }:extend(self:get_party():get_party_members(true):map(function(p) return p:get_id() end)))
    }
    return Condition.check_conditions(conditions, target:get_mob().index)
end

function Puller:get_pull_target()
    return self.target
end

function Puller:set_pull_target(target)
    if self.target then
        self.target:destroy()
    end
    self.target = target
end

function Puller:get_pull_settings()
    return self.pull_settings
end

function Puller:set_pull_settings(pull_settings)
    self.pull_settings = pull_settings
    self.pull_abilities = self.pull_settings.Abilities or L{}
end

function Puller:get_pull_abilities()
    if state.ApproachPullMode.value ~= 'Off' then
        return L{ Approach.new() }
    end
    return self.pull_abilities
end

function Puller:get_blacklist()
    return self.blacklist
end

function Puller:set_blacklist(blacklist)
    self.blacklist = blacklist
end

function Puller:get_type()
    return "puller"
end

function Puller:set_target_names(target_names)
    self.target_names = target_names
end

function Puller:get_target_names()
    if state.AutoPullMode.value == 'All' then
        return L{}
    end
    return self.target_names
end

function Puller:set_camp_position(position)
    self.camp_position = position
end

function Puller:get_camp_position()
    return self.camp_position
end

function Puller:allows_duplicates()
    return false
end

return Puller