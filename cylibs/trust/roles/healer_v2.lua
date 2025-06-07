local AggroedCondition = require('cylibs/conditions/aggroed')
local ConditionalCondition = require('cylibs/conditions/conditional')
local Disengage = require('cylibs/battle/disengage')
local DisposeBag = require('cylibs/events/dispose_bag')
local Distance = require('cylibs/conditions/distance')
local Engage = require('cylibs/battle/engage')
local Target = require('cylibs/battle/target')
local GambitTarget = require('cylibs/gambits/gambit_target')
local IsAssistTargetCondition = require('cylibs/conditions/is_assist_target')
local PartyClaimedCondition = require('cylibs/conditions/party_claimed')
local TargetMismatchCondition = require('cylibs/conditions/target_mismatch')
local UnclaimedCondition = require('cylibs/conditions/unclaimed')

local Reacter = require('cylibs/trust/roles/reacter')
local Healer = setmetatable({}, {__index = Reacter })
Healer.__index = Healer
Healer.__class = "Healer"

state.AutoHealMode = M{['description'] = 'Heal Player and Party', 'Auto', 'Emergency', 'Off'}
state.AutoHealMode:set_description('Auto', "Heal the party using the Default cure threshold.")
state.AutoHealMode:set_description('Emergency', "Heal the party using the Emergency cure threshold.")

function Healer.new(action_queue)
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, L{ state.AutoHealMode }), Healer)

    self.dispose_bag = DisposeBag.new()

    self:set_healer_settings({})

    return self
end

function Healer:destroy()
    Reacter.destroy(self)

    self.dispose_bag:destroy()
end

function Healer:on_add()
    Reacter.on_add(self)

    self.dispose_bag:add(self:get_party():on_party_target_change():addAction(function(_, _)
        self:check_gambits()
    end), self:get_party():on_party_target_change())
end

function Healer:set_attacker_settings(_)
    local gambit_settings = {
        Gambits = L{
            Gambit.new(GambitTarget.TargetType.Enemy, L{
                GambitCondition.new(ModeCondition.new('AutoEngageMode', 'Always'), GambitTarget.TargetType.Self),
                GambitCondition.new(StatusCondition.new('Idle'), GambitTarget.TargetType.Self),
                GambitCondition.new(MaxDistanceCondition.new(30), GambitTarget.TargetType.Enemy),
                GambitCondition.new(AggroedCondition.new(), GambitTarget.TargetType.Enemy),
                GambitCondition.new(ConditionalCondition.new(L{ UnclaimedCondition.new(), PartyClaimedCondition.new(true) }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Enemy),
                GambitCondition.new(ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()), GambitTarget.TargetType.Enemy),
            }, Engage.new(), GambitTarget.TargetType.Enemy),
            Gambit.new(GambitTarget.TargetType.Enemy, L{
                GambitCondition.new(ModeCondition.new('AutoEngageMode', 'Mirror'), GambitTarget.TargetType.Self),
                GambitCondition.new(IsAssistTargetCondition.new(), GambitTarget.TargetType.Ally),
                GambitCondition.new(StatusCondition.new('Engaged'), GambitTarget.TargetType.Ally),
                GambitCondition.new(StatusCondition.new('Idle'), GambitTarget.TargetType.Self),
                GambitCondition.new(MaxDistanceCondition.new(30), GambitTarget.TargetType.Enemy),
                GambitCondition.new(ConditionalCondition.new(L{ UnclaimedCondition.new(), PartyClaimedCondition.new(true) }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Enemy),
                GambitCondition.new(ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()), GambitTarget.TargetType.Enemy),
            }, Engage.new(), GambitTarget.TargetType.Enemy),
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(ModeCondition.new('AutoEngageMode', 'Mirror'), GambitTarget.TargetType.Self),
                GambitCondition.new(IsAssistTargetCondition.new(), GambitTarget.TargetType.Ally),
                GambitCondition.new(StatusCondition.new('Idle'), GambitTarget.TargetType.Ally),
                GambitCondition.new(StatusCondition.new('Engaged'), GambitTarget.TargetType.Self),
            }, Disengage.new(), GambitTarget.TargetType.Self),
            Gambit.new(GambitTarget.TargetType.Enemy, L{
                GambitCondition.new(NotCondition.new(L{ ModeCondition.new('PullActionMode', 'Target') }), GambitTarget.TargetType.Self),
                GambitCondition.new(StatusCondition.new('Idle'), GambitTarget.TargetType.Self),
                GambitCondition.new(TargetMismatchCondition.new(), GambitTarget.TargetType.Self),
            }, Target.new(), GambitTarget.TargetType.Self), -- TODO: should I also remove aggroed condition from this??
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

    gambit_settings.Gambits = L{
        -- we do not want IsAggroedCondition here
        Gambit.new(GambitTarget.TargetType.Self, L{
            GambitCondition.new(StatusCondition.new('Engaged'), GambitTarget.TargetType.Self),
            GambitCondition.new(Distance.new(30, Condition.Operator.GreaterThanOrEqualTo), GambitTarget.TargetType.CurrentTarget),
        }, Disengage.new(), GambitTarget.TargetType.Self),
        Gambit.new(GambitTarget.TargetType.Enemy, L{
            GambitCondition.new(StatusCondition.new('Engaged'), GambitTarget.TargetType.Self),
            GambitCondition.new(TargetMismatchCondition.new(), GambitTarget.TargetType.Self),
        }, Engage.new(), GambitTarget.TargetType.Self),
    } + gambit_settings.Gambits

    self:set_gambit_settings(gambit_settings)
end

function Healer:get_default_conditions(gambit)
    local conditions = L{
        GambitCondition.new(AggroedCondition.new(), GambitTarget.TargetType.Enemy),
    }
    return conditions:map(function(condition)
        if condition.__type ~= GambitCondition.__type then
            return GambitCondition.new(condition, GambitTarget.TargetType.Self)
        end
        return condition
    end)
end

function Healer:get_cooldown()
    return 1
end

function Healer:allows_multiple_actions()
    return false
end

function Healer:get_type()
    return "healer"
end

function Healer:allows_duplicates()
    return false
end

return Healer