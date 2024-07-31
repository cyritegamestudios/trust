local battle_util = require('cylibs/util/battle_util')
local party_util = require('cylibs/util/party_util')
local BlockAction = require('cylibs/actions/block')
local CommandAction = require('cylibs/actions/command')
local DisengageAction = require('cylibs/actions/disengage')

local Attacker = setmetatable({}, {__index = Role })
Attacker.__index = Attacker

state.AutoEngageMode = M{['description'] = 'Auto Engage Mode', 'Off', 'Always', 'Mirror', 'Assist'}
state.AutoEngageMode:set_description('Off', "Okay, I won't engage or target mobs our party is fighting.")
state.AutoEngageMode:set_description('Always', "Okay, I'll automatically engage when our party is fighting.")
state.AutoEngageMode:set_description('Mirror', "Okay, I'll only engage if the person I'm assisting is fighting.")
state.AutoEngageMode:set_description('Assist', "Okay, I'll lock onto the target but I won't draw my weapons.")

state.EngageMode = M{['description'] = 'Engage Mode', 'None', 'Behind'}
state.EngageMode:set_description('Behind', "Okay, I'll get behind the monster when fighting.")

function Attacker.new(action_queue)
    local self = setmetatable(Role.new(action_queue), Attacker)
    self.action_queue = action_queue
    self.action_events = {}
    return self
end

function Attacker:destroy()
    Role.destroy(self)

    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
end

function Attacker:on_add()
end

function Attacker:target_change(target_index)
    Role.target_change(self, target_index)

    self.target_index = target_index

    self:tic(os.time() - 3, os.time())
end

function Attacker:tic(_, _)
    if state.AutoEngageMode.value == 'Off' or self.target_index == nil then
        return
    end
    self:check_engage()
end

function Attacker:check_engage()
    local target = windower.ffxi.get_mob_by_index(self.target_index)
    if target == nil or not battle_util.is_valid_target(target.id) or not party_util.party_claimed(target.id) then
        return
    end

    local current_player_status = player.status
    if current_player_status == 'Idle' then
        if state.AutoEngageMode.value == 'Always' then
            self:attack_mob(target)
        elseif state.AutoEngageMode.value == 'Mirror' then
            if self:get_party():get_assist_target():get_status() == 'Engaged' then
                self:attack_mob(target)
            end
        elseif state.AutoEngageMode.value == 'Assist' then
            self.action_queue:push_action(CommandAction.new(0, 0, 0, '/assist '..self:get_party():get_assist_target():get_name()), true)
        end
    elseif current_player_status == 'Engaged' then
        if state.AutoEngageMode.value == 'Mirror' then
            if self:get_party():get_assist_target():get_status() == 'Idle' then
                self.action_queue:push_action(CommandAction.new(0, 0, 0, '/attackoff'), true)
            else
                if self:get_party():get_assist_target():get_status() == 'Engaged' then
                    self:attack_mob(target)
                end
            end
        else
            if target.index ~= windower.ffxi.get_player().target_index then
                if state.AutoEngageMode.value == 'Always' then
                    self:attack_mob(target)
                elseif state.AutoEngageMode.value == 'Assist' then
                    self.action_queue:push_action(CommandAction.new(0, 0, 0, '/assist '..self:get_party():get_assist_target():get_name()), true)
                end
                self:get_party():add_to_chat(self:get_party():get_player(), "Alright, I'll fight the "..target.name.." with you now.", 30)
            end
        end
    end
end

function Attacker:attack_mob(target)
    if player.status == 'Engaged' and self:is_targeting_self() then
        local disengage_action = DisengageAction.new()
        disengage_action.priority = ActionPriority.high

        self.action_queue:push_action(disengage_action, true)
    else
        local attack_action = BlockAction.new(function() battle_util.target_mob(target.index) end, "attacker_engage")
        attack_action.priority = ActionPriority.high

        self.action_queue:push_action(attack_action, true)
    end
end

function Attacker:is_targeting_self()
    local current_target_index = windower.ffxi.get_player().target_index
    if current_target_index then
        if current_target_index == windower.ffxi.get_player().index then
            return true
        end
    end
    return false
end

function Attacker:allows_duplicates()
    return false
end

function Attacker:get_type()
    return "attacker"
end

return Attacker