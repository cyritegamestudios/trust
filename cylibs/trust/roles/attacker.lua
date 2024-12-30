local ClaimedCondition = require('cylibs/conditions/claimed')
local CommandAction = require('cylibs/actions/command')
local ConditionalCondition = require('cylibs/conditions/conditional')
local DisengageAction = require('cylibs/actions/disengage')
local DisposeBag = require('cylibs/events/dispose_bag')
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
    self.dispose_bag = DisposeBag.new()
    return self
end

function Attacker:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()

    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
end

function Attacker:on_add()
    self.dispose_bag:add(WindowerEvents.StatusChanged:addAction(function(mob_id, status)
        if state.AutoEngageMode.value ~= 'Mirror' then
            return
        end
        if windower.ffxi.get_mob_by_id(mob_id).name == 'Cyrite' then
            print(windower.ffxi.get_mob_by_id(mob_id).name, status)
        end
        if mob_id == self:get_party():get_assist_target():get_id()
                and status ~= self:get_party():get_player():get_status() then
                --and status ~= self.last_status then
            --self.last_status = t
            self:check_engage()
        end
    end), WindowerEvents.StatusChanged)
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
        ConditionalCondition.new(L{ UnclaimedCondition.new(target.index), ClaimedCondition.new(self:get_alliance():get_alliance_member_ids()) }, Condition.LogicalOperator.Or),
        ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos())
    }

    if not Condition.check_conditions(conditions, target.index) then
        return false
    end
    return true
end

function Attacker:check_engage()
    logger.notice(self.__class, 'check_engage')

    local target = self.target_index and windower.ffxi.get_mob_by_index(self.target_index)

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
                local disengage_action = DisengageAction.new()
                disengage_action.priority = ActionPriority.high

                self.action_queue:push_action(disengage_action, true)
                print('disengage', os.time())
            else
                if self:get_party():get_assist_target():get_status() == 'Engaged' then
                    self:attack_mob(target)
                end
            end
        else
            if target.index ~= windower.ffxi.get_player().target_index then
                if state.AutoEngageMode.value == 'Always' then
                    self:attack_mob(target)
                end
                self:get_party():add_to_chat(self:get_party():get_player(), "Alright, I'll fight the "..target.name.." with you now.", 30)
            end
        end
    end
end

function Attacker:attack_mob(target)
    if not self:can_engage(target) then
        return
    end

    local conditions = L{ ConditionalCondition.new(L{ UnclaimedCondition.new(target.index), ClaimedCondition.new(self:get_alliance():get_alliance_member_ids()) }, Condition.LogicalOperator.Or) }
    if target == nil or not Condition.check_conditions(conditions, target.index)
            or (windower.ffxi.get_player().target_index == target.index and self:get_party():get_player():get_status() == 'Engaged') then
        return
    end

    if player.status == 'Engaged' and self:is_targeting_self() then
        local disengage_action = DisengageAction.new()
        disengage_action.priority = ActionPriority.high

        self.action_queue:push_action(disengage_action, true)
    else
        local attack_action = Engage.new(target.index):to_action(target.index)
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