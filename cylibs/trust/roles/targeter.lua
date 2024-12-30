local Targeter = setmetatable({}, {__index = Role })
Targeter.__index = Targeter
Targeter.__class = "Targeter"

local ClaimedCondition = require('cylibs/conditions/claimed')
local ConditionalCondition = require('cylibs/conditions/conditional')
local DisposeBag = require('cylibs/events/dispose_bag')
local Engage = require('cylibs/actions/engage')
local MobFilter = require('cylibs/battle/monsters/mob_filter')
local Timer = require('cylibs/util/timers/timer')

state.AutoTargetMode = M{['description'] = 'Auto Target Mode', 'Off', 'Auto', 'Mirror'}
state.AutoTargetMode:set_description('Auto', "Okay, I'll automatically target aggroed monsters after we defeat one.")
state.AutoTargetMode:set_description('Mirror', "Okay, I'll target what the person I'm assisting is fighting.")

function Targeter.new(action_queue)
    local self = setmetatable(Role.new(action_queue), Targeter)

    self.action_queue = action_queue
    self.action_identifier = 'autotarget'
    self.should_retry = false
    self.target_timer = Timer.scheduledTimer(1, 0)
    self.last_checked_targets = os.time()

    self.dispose_bag = DisposeBag.new()
    self.dispose_bag:addAny(L{ self.target_timer })

    return self
end

function Targeter:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function Targeter:check_state_for_assist(assist_target)
    if not L{ 'Off', 'Mirror' }:contains(state.AutoTargetMode.value) and assist_target and not assist_target:is_player() then
        state.AutoTargetMode:set('Off')
        self:get_party():add_to_chat(self:get_party():get_player(), "No need to auto target, I'll already target what "..assist_target:get_name().." targets!")
    end
end

function Targeter:on_add()
    self.mob_filter = MobFilter.new(self:get_alliance(), 25, function(mob1, mob2)
        local party_target_indices = S(self:get_party():get_party_members(true):map(function(p)
            return p:get_target_index()
        end))
        if not party_target_indices:contains(mob1.index) and party_target_indices:contains(mob2.index) then
            return true
        elseif party_target_indices:contains(mob1.index) and not party_target_indices:contains(mob2.index) then
            return false
        elseif mob1.distance ~= mob2.distance then
            return mob1.distance < mob2.distance
        else
            return mob1.index < mob2.index
        end
    end)

    self.dispose_bag:addAny(L{ self.mob_filter })

    self.dispose_bag:add(state.AutoTargetMode:on_state_change():addAction(function(_, new_value)
        if not L{ 'Off' }:contains(new_value) then
            windower.send_command('input /autotarget off')
            local assist_target = self:get_party():get_assist_target()
            self:check_state_for_assist(assist_target)
        end
    end), state.AutoTargetMode:on_state_change())

    self.dispose_bag:add(state.AutoPullMode:on_state_change():addAction(function(_, new_value)
        if new_value ~= 'Off' and state.AutoTargetMode.value ~= 'Off' then
            state.AutoTargetMode:set('Off')
            self:get_party():add_to_chat(self:get_party():get_player(), "No need to auto target, I'll already target what I'm pulling!")
        end
    end), state.AutoPullMode:on_state_change())

    self.dispose_bag:add(self:get_party():on_party_assist_target_change():addAction(function(_, assist_target)
        self:check_state_for_assist(assist_target)
    end), self:get_party():on_party_assist_target_change())

    self.dispose_bag:add(self.target_timer:onTimeChange():addAction(function(_)
        self:check_target()
    end, self.target_timer:onTimeChange()))

    self.dispose_bag:add(WindowerEvents.MobKO:addAction(function(mob_id, mob_name)
        if self:get_target() and self:get_target():get_id() == mob_id then
            self:check_target(true)
        end
    end), WindowerEvents.MobKO)
end

function Targeter:target_change(target_index)
    Role.target_change(self, target_index)

    if state.AutoTargetMode.value == 'Mirror' then
        local assist_target_index = self:get_party():get_assist_target():get_target_index()
        if windower.ffxi.get_player().target_index ~= assist_target_index then
            local target = self:get_party():get_target_by_index(assist_target_index)
            if target and target:get_mob().status ~= 0 then
                self:get_party():add_to_chat(self.party:get_player(), "I'm switching targets to the "..target:get_mob().name.." now.")
                self:target_mob(target:get_mob())
            end
        end
    end
end

function Targeter:tic(new_time, old_time)
    Role.tic(self, new_time, old_time)

    if self:should_auto_target() then
        self:check_target(player.status == 'Idle')
    end
end

function Targeter:check_target(override_current_target)
    if S{ 'Off', 'Mirror' }:contains(state.AutoTargetMode.value) or (not override_current_target and os.time() - self.last_checked_targets < 1) then
        return
    end
    self.last_checked_targets = os.time()

    local current_target = self:get_target()
    if not override_current_target and current_target then
        return
    end

    logger.notice(self.__class, 'check_target')

    local all_targets = self:get_all_targets()
    if all_targets:length() > 0 then
        local party_target_indices = S(self:get_party():get_party_members(true):map(function(p)
            return p:get_target_index()
        end))
        local targets = all_targets:filter(function(mob)
            return not party_target_indices:contains(mob.index)
        end)
        if targets:length() > 0 then
            logger.notice(self.__class, 'check_target', 'found', 'untargeted', targets[1].name, targets[1].distance:sqrt())
            self:target_mob(targets:random())
        else
            logger.notice(self.__class, 'check_target', 'found', 'targeted', all_targets[1].name, all_targets[1].distance:sqrt())
            self:target_mob(all_targets[1])
        end
    else
        logger.notice(self.__class, 'check_target', 'no targets')
        self:get_party():add_to_chat(self.party:get_player(), "There's nothing for me to auto target.", self.__class..'no_target', 20, true)
    end
end

function Targeter:target_mob(target)
    local conditions = L{ ConditionalCondition.new(L{ UnclaimedCondition.new(target.index), ClaimedCondition.new(self:get_alliance():get_alliance_member_ids()) }, Condition.LogicalOperator.Or) }
    if not Condition.check_conditions(conditions, target.index) then
        return
    end

    if self.action_queue:has_action(self.action_identifier) then
        return
    end
    self.action_queue:clear()

    local target_action = Engage.new(target.index)
    target_action.priority = ActionPriority.high
    target_action.identifier = self.action_identifier

    self.action_queue:push_action(target_action, true)

    windower.send_command('input /echo Auto targeting '..target.name..'.')
end

function Targeter:get_all_targets()
    local targets = self.mob_filter:get_aggroed_mobs():filter(function(mob)
        if self:get_target() then
            return mob.id ~= self:get_target().id
        end
        return true
    end)
    return targets or L{}
end

function Targeter:should_auto_target()
    return self.should_retry
end

function Targeter:allows_duplicates()
    return false
end

function Targeter:get_type()
    return "targeter"
end

function Targeter:set_target_settings(target_settings)
    self.should_retry = target_settings.Retry
end

return Targeter
