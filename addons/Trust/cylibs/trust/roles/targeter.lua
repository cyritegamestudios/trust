local Targeter = setmetatable({}, {__index = Role })
Targeter.__index = Targeter

state.AutoTargetMode = M{['description'] = 'Auto Target Mode', 'Off', 'Auto', 'Same'}
state.AutoTargetMode:set_description('Auto', "Okay, I'll automatically target a new monster after we defeat one.")
state.AutoTargetMode:set_description('Same', "Okay, I'll automatically target a new monster with the same name as the last one we defeated.")

function Targeter.new(action_queue)
    local self = setmetatable(Role.new(action_queue), Targeter)
    self.action_queue = action_queue
    self.action_events = {}
    self.auto_target_index = nil
    return self
end

function Targeter:destroy()
    Role.destroy(self)

    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
end

function Targeter:on_add()
    state.AutoTargetMode:on_state_change():addAction(function(_, new_value)
        if new_value ~= 'Off' then
            windower.send_command('input /autotarget off')
        end
    end)

    self.action_events.action_message = windower.register_event('action message', function(actor_id, target_id, actor_index, target_index, message_id, _, _, _)
        if state.AutoTargetMode.value == 'Off' or self.auto_target_index == nil or self.auto_target_index ~= target_index then
            return
        end

        -- Monster is defeated
        if action_message_util.is_monster_defeated(message_id) then
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
    end)

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
end

function Targeter:allows_duplicates()
    return false
end

function Targeter:get_type()
    return "targeter"
end

return Targeter
