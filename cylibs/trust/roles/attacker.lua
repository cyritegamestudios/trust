local ClaimedCondition = require('cylibs/conditions/claimed')
local CommandAction = require('cylibs/actions/command')
local ConditionalCondition = require('cylibs/conditions/conditional')
local DisengageAction = require('cylibs/actions/disengage')
local Engage = require('cylibs/battle/engage')
local UnclaimedCondition = require('cylibs/conditions/unclaimed')

local Attacker = setmetatable({}, {__index = Role })
Attacker.__index = Attacker
Attacker.__class = "Attacker"

state.AutoEngageMode = M{['description'] = 'Auto Engage Mode', 'Off', 'Always', 'Mirror'}
state.AutoEngageMode:set_description('Off', "Okay, I won't engage or target mobs our party is fighting.")
state.AutoEngageMode:set_description('Always', "Okay, I'll automatically engage when our party is fighting.")
state.AutoEngageMode:set_description('Mirror', "Okay, I'll only engage if the person I'm assisting is fighting.")

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

    if self.target_index == windower.ffxi.get_player().index then
        self.last_target_self = os.time()
    else
        self.last_target_self = nil
    end

    self:check_engage()
end

function Attacker:tic(_, _)
    if state.AutoEngageMode.value == 'Off' or self:get_target() == nil then
        return
    end
    self:check_engage()
end

function Attacker:can_engage(target)
    if target == nil then
        return false
    end

    local conditions = L{
        ConditionalCondition.new(L{ UnclaimedCondition.new(target:get_index()), ClaimedCondition.new(self:get_alliance():get_alliance_member_ids()) }, Condition.LogicalOperator.Or),
        ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos())
    }
    print(target:get_index())
    if not Condition.check_conditions(conditions, target:get_index()) then
        return false
    end
    return true
end

function Attacker:check_engage()
    logger.notice(self.__class, 'check_engage')

    local target = self:get_target()
    if not self:can_engage(target) then
        return
    end

    local current_player_status = self:get_party():get_player():get_status()
    if current_player_status == 'Idle' then
        logger.notice(self.__class, 'check_engage', 'Idle')
        if state.AutoEngageMode.value == 'Always' then
            self:attack_mob(target)
        elseif state.AutoEngageMode.value == 'Mirror' and not self:get_party():get_assist_target():is_player() then
            if self:get_party():get_assist_target():get_status() == 'Engaged' then
                self:attack_mob(target)
            end
        end
    elseif current_player_status == 'Engaged' then
        logger.notice(self.__class, 'check_engage', 'Engaged')
        if state.AutoEngageMode.value == 'Mirror' and not self:get_party():get_assist_target():is_player() then
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
    local conditions = L{ ConditionalCondition.new(L{ UnclaimedCondition.new(target:get_index()), ClaimedCondition.new(self:get_alliance():get_alliance_member_ids()) }, Condition.LogicalOperator.Or) }
    if target == nil or not Condition.check_conditions(conditions, target:get_index())
            or (windower.ffxi.get_player().target_index == target:get_index() and self:get_party():get_player():get_status() == 'Engaged') then
        return
    end

    if player.status == 'Engaged' and self:is_targeting_self() then
        local disengage_action = DisengageAction.new()
        disengage_action.priority = ActionPriority.high

        self.action_queue:push_action(disengage_action, true)
    else
        local attack_action = Engage.new(target:get_index()):to_action(target:get_index())
        attack_action.priority = ActionPriority.high

        self.action_queue:push_action(attack_action, true)
    end
end

function Attacker:is_targeting_self()
    if self.last_target_self == nil then
        return
    end
    local current_target_index = windower.ffxi.get_player().target_index
    if current_target_index then
        if current_target_index == windower.ffxi.get_player().index and (os.time() - self.last_target_self) > 6 then
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