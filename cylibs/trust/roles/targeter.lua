local Targeter = setmetatable({}, {__index = Role })
Targeter.__index = Targeter
Targeter.__class = "Targeter"

local DisposeBag = require('cylibs/events/dispose_bag')

state.AutoTargetMode = M{['description'] = 'Auto Target Mode', 'Off', 'Auto', 'Same', 'Party'}
state.AutoTargetMode:set_description('Auto', "Okay, I'll automatically target a new monster after we defeat one.")
state.AutoTargetMode:set_description('Same', "Okay, I'll automatically target a new monster with the same name as the last one we defeated.")
state.AutoTargetMode:set_description('Party', "Okay, I'll automatically target monsters on the party's hate list.")

function Targeter.new(action_queue)
    local self = setmetatable(Role.new(action_queue), Targeter)
    self.action_queue = action_queue
    self.action_events = {}
    self.last_checked_targets = os.time()
    self.auto_target_index = nil
    self.dispose_bag = DisposeBag.new()
    return self
end

function Targeter:destroy()
    Role.destroy(self)

    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end

    self.dispose_bag:destroy()
end

function Targeter:on_add()
    state.AutoTargetMode:on_state_change():addAction(function(_, new_value)
        if new_value ~= 'Off' then
            windower.send_command('input /autotarget off')
        end
    end)

    self.dispose_bag:add(WindowerEvents.ActionMessage:addAction(function(actor_id, target_id, actor_index, target_index, message_id, _, _, _)
        if state.AutoTargetMode.value == 'Off' or self.auto_target_index == nil or self.auto_target_index ~= target_index then
            return
        end

        -- Monster is defeated
        if action_message_util.is_monster_defeated(message_id) then
            if state.AutoTargetMode.value == 'Party' then
                self:check_targets(true)
            else
                local target_mobs = L{}
                if state.AutoTargetMode.value == 'Same' then
                    local target = windower.ffxi.get_mob_by_id(target_id)
                    if target then
                        target_mobs = L{ target.name }
                    end
                end

                local auto_target_mob = ffxi_util.find_closest_mob(target_mobs, L{self.auto_target_index}:extend(party_util.party_targets()))
                if auto_target_mob and auto_target_mob.distance:sqrt() < 25 then
                    self:target_mob(auto_target_mob)
                else
                    local party_claimed_mob = ffxi_util.find_closest_mob(L{}, L{player.target_index})
                    if party_claimed_mob and party_claimed_mob.distance:sqrt() < 25 then
                        self:target_mob(party_claimed_mob)
                    else
                        windower.send_command('input /echo No mobs to auto target.')
                    end
                end
            end
        end
    end), WindowerEvents.ActionMessage)

    self.action_events.target_change = windower.register_event('target change', function(new_target_index)
        if state.AutoTargetMode.value == 'Off' then return end

        self.auto_target_index = new_target_index
    end)
end

function Targeter:target_mob(target)
    local attack_action = BlockAction.new(function() battle_util.target_mob(target.index) end, "attacker_engage")
    attack_action.priority = ActionPriority.high

    self.action_queue:push_action(attack_action, true)

    windower.send_command('input /echo Auto targeting '..target.name..'.')
end

function Targeter:target_change(target_index)
    Role.target_change(self, target_index)

    self.target_index = target_index
end

function Targeter:tic(new_time, old_time)
    Role.tic(self, new_time, old_time)

    self:check_targets()
end

function Targeter:check_targets(ignore_cooldown)
    if state.AutoTargetMode.value ~= 'Party' or (not ignore_cooldown and os.time() - self.last_checked_targets < 3) then
        return
    end
    self.last_checked_targets = os.time()

    local current_target = self:get_target()
    if current_target then
        return
    end

    logger.notice(self.__class, 'check_targets')

    local targets = self:get_party():get_targets(function(target)
        return target:get_distance():sqrt() < 12 and target:get_mob().status == 1
    end)
    if targets:length() > 0 then
        local next_target = targets:firstWhere(function(target)
            return target and not party_util.party_targeted(target:get_id())
        end) or targets[1]

        logger.notice(self.__class, 'check_targets', 'found', next_target:get_name(), next_target:get_distance())

        self:target_mob(next_target:get_mob())
    end
end

function Targeter:get_all_targets()
    if state.AutoTargetMode.value == 'Party' then
        local targets = self:get_party():get_targets(function(target)
            return target:get_distance():sqrt() < 15 and target:get_mob().status == 1
        end)
        return targets
    end
    return L{}
end

function Targeter:allows_duplicates()
    return false
end

function Targeter:get_type()
    return "targeter"
end

return Targeter
