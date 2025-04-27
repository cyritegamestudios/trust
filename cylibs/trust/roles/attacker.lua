local AggroedCondition = require('cylibs/conditions/aggroed')
local ConditionalCondition = require('cylibs/conditions/conditional')
local Disengage = require('cylibs/battle/disengage')
local DisposeBag = require('cylibs/events/dispose_bag')
local Engage = require('cylibs/battle/engage')
local GambitTarget = require('cylibs/gambits/gambit_target')
local IsAssistTargetCondition = require('cylibs/conditions/is_assist_target')
local PartyClaimedCondition = require('cylibs/conditions/party_claimed')
local UnclaimedCondition = require('cylibs/conditions/unclaimed')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Attacker = setmetatable({}, {__index = Gambiter })
Attacker.__index = Attacker
Attacker.__class = "Attacker"

state.AutoEngageMode = M{['description'] = 'Auto Engage Mode', 'Off', 'Always', 'Mirror'}
state.AutoEngageMode:set_description('Off', "Manually engage and disengage.")
state.AutoEngageMode:set_description('Always', "Automatically engage when targeting a claimed mob.")
state.AutoEngageMode:set_description('Mirror', "Mirror the engage status of the party member you are assisting.")

function Attacker.new(action_queue)
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, state.AutoEngageMode), Attacker)

    self.dispose_bag = DisposeBag.new()

    self:set_attacker_settings({})

    return self
end

function Attacker:destroy()
    Gambiter.destroy(self)

    self.dispose_bag:destroy()
end

function Attacker:on_add()
    Gambiter.on_add(self)

    self.dispose_bag:add(self:get_party():on_party_target_change():addAction(function(_, _)
        self:check_gambits()
    end), self:get_party():on_party_target_change())
end

function Attacker:target_change(_)
    Gambiter.target_change(self)

    self:check_gambits()
end

function Attacker:set_attacker_settings(_)
    local gambit_settings = {
        Gambits = L{
            Gambit.new(GambitTarget.TargetType.Enemy, L{
                GambitCondition.new(StatusCondition.new('Idle'), GambitTarget.TargetType.Self),
                GambitCondition.new(ModeCondition.new('AutoPullMode', 'Off'), GambitTarget.TargetType.Self),
                GambitCondition.new(MaxDistanceCondition.new(30), GambitTarget.TargetType.Enemy),
                GambitCondition.new(AggroedCondition.new(), GambitTarget.TargetType.Enemy),
                GambitCondition.new(ConditionalCondition.new(L{ UnclaimedCondition.new(), PartyClaimedCondition.new(true) }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Enemy),
                GambitCondition.new(ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos(), ValidTargetCondition.EntityType.Monster), GambitTarget.TargetType.Enemy),
            }, Engage.new(), GambitTarget.TargetType.Self),
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(ModeCondition.new('AutoEngageMode', 'Mirror'), GambitTarget.TargetType.Self),
                GambitCondition.new(StatusCondition.new('Engaged'), GambitTarget.TargetType.Self),
                GambitCondition.new(IsAssistTargetCondition.new(), GambitTarget.TargetType.Ally),
                GambitCondition.new(StatusCondition.new('Idle'), GambitTarget.TargetType.Ally),
            }, Disengage.new(), GambitTarget.TargetType.Self)
        }
    }

    for gambit in gambit_settings.Gambits:it() do
        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = self:get_default_conditions(gambit)
        for condition in conditions:it() do
            condition:set_editable(false)
            gambit:addCondition(condition)
        end
    end

    self:set_gambit_settings(gambit_settings)
end

function Attacker:get_default_conditions(gambit)
    local conditions = L{
    }
    return (conditions --[[+ self.job:get_conditions_for_ability(gambit:getAbility())]]):map(function(condition)
        if condition.__type ~= GambitCondition.__type then
            return GambitCondition.new(condition, GambitTarget.TargetType.Self)
        end
        return condition
    end)
end

function Attacker:get_cooldown()
    return 6
end

function Attacker:allows_multiple_actions()
    return false
end

function Attacker:get_type()
    return "attacker"
end

function Attacker:allows_duplicates()
    return false
end



--[[function Attacker:on_add()
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
    self:validate_target()
    self:check_engage()
end

function Attacker:validate_target()
    local target = self:get_target()
    if target == nil then
        return
    end
    logger.notice(self.__class, 'validate_target')
    if self:get_party():get_player():get_status() == 'Engaged' then
        local current_target = windower.ffxi.get_mob_by_target('t')
        if current_target and battle_util.is_valid_monster_target(current_target.id) then
            if current_target.index ~= self.target_index then
                logger.error(self.__class, 'validate_target', 'disengaging', 'current target', current_target.index, current_target.hpp, current_target.status,
                        'trust target', target.index, target.hpp, target.status)
                self:disengage()
            end
        end
    end
end

function Attacker:check_engage()
    if state.AutoEngageMode.value == 'Off' or state.AutoPullMode.value ~= 'Off' then
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
end]]

return Attacker