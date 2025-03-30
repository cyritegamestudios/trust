local AggroedCondition = require('cylibs/conditions/aggroed')
local ClaimedCondition = require('cylibs/conditions/claimed')
local ConditionalCondition = require('cylibs/conditions/conditional')
local DisengageAction = require('cylibs/actions/disengage')
local DisposeBag = require('cylibs/events/dispose_bag')
local Engage = require('cylibs/battle/engage')
local monster_util = require('cylibs/util/monster_util')
local UnclaimedCondition = require('cylibs/conditions/unclaimed')

local Attacker = setmetatable({}, {__index = Role })
Attacker.__index = Attacker
Attacker.__class = "Attacker"

state.AutoEngageMode = M{['description'] = 'Auto Engage Mode', 'Off', 'Always', 'Mirror'}
state.AutoEngageMode:set_description('Off', "Manually engage and disengage.")
state.AutoEngageMode:set_description('Always', "Automatically engage when targeting a claimed mob.")
state.AutoEngageMode:set_description('Mirror', "Mirror the engage status of the party member you are assisting.")

function Attacker.new(action_queue)
    local self = setmetatable(Role.new(action_queue), Attacker)
    self.action_queue = action_queue
    self.assist_target_dispose_bag = DisposeBag.new()
    self.dispose_bag = DisposeBag.new()
    self.dispose_bag:addAny(L{ self.assist_target_dispose_bag })
    return self
end

function Attacker:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function Attacker:on_add()
    local on_assist_target_change = function(assist_target)
        self.assist_target_dispose_bag:dispose()

        if not assist_target:is_player() then
            self.assist_target_dispose_bag:add(assist_target:on_status_change():addAction(function(_, _, _)
                self:check_engage()
            end), assist_target:on_status_change())
        end
    end

    self.dispose_bag:add(self:get_party():on_party_assist_target_change():addAction(function(_, assist_target)
        on_assist_target_change(assist_target)
    end), self:get_party():on_party_assist_target_change())

    on_assist_target_change(self:get_party():get_assist_target())
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
    self:check_engage()
end

function Attacker:check_engage()
    if state.AutoEngageMode.value == 'Off' then
        return
    end

    logger.notice(self.__class, 'check_engage')

    if self:should_disengage() then
        self:disengage()
    else
        local engage_target = self:get_engage_target()
        if engage_target then
            if self:should_engage(engage_target) then
                self:engage(engage_target)
            end
        else
            self:disengage()
        end
    end
end

function Attacker:can_engage(target)
    if target == nil then
        return false
    end

    local conditions = L{
        AggroedCondition.new(),
        MinHitPointsPercentCondition.new(1),
        ConditionalCondition.new(L{ UnclaimedCondition.new(target:get_index()), ClaimedCondition.new(self:get_alliance():get_alliance_member_ids()) }, Condition.LogicalOperator.Or),
        ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos())
    }
    if not Condition.check_conditions(conditions, target:get_index()) then
        return false
    end
    return true
end

function Attacker:should_engage(target)
    if target == nil then
        return false
    end

    local conditions = L{
        AggroedCondition.new(),
    }
    if not Condition.check_conditions(conditions, target:get_index()) then
        return false
    end
    return true
end

function Attacker:engage(target)
    if not self:can_engage(target) or (windower.ffxi.get_mob_by_target('t') and windower.ffxi.get_mob_by_target('t').index == target:get_index() and self:get_party():get_player():get_status() == 'Engaged') then
        return
    end

    local attack_action = Engage.new(target:get_index()):to_action(target:get_index())
    attack_action.priority = ActionPriority.high

    self.action_queue:push_action(attack_action, true)
end

function Attacker:get_engage_target()
    if state.AutoEngageMode.value == 'Off' then
        return nil
    else
        return self:get_target() or (monster_util.id_for_index(self.target_index) and Monster.new(monster_util.id_for_index(self.target_index)))
    end
end

function Attacker:should_disengage()
    local assist_target = self:get_party():get_assist_target()
    return state.AutoEngageMode.value == 'Mirror' and not assist_target:is_player() and assist_target:get_status() == 'Idle'
end

function Attacker:disengage()
    if self:get_party():get_player():get_status() == 'Idle' then
        return
    end

    local disengage_action = DisengageAction.new()
    disengage_action.priority = ActionPriority.high

    self.action_queue:push_action(disengage_action, true)
end

function Attacker:allows_duplicates()
    return false
end

function Attacker:get_type()
    return "attacker"
end

return Attacker