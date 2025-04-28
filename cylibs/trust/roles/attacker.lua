local AggroedCondition = require('cylibs/conditions/aggroed')
local ConditionalCondition = require('cylibs/conditions/conditional')
local Disengage = require('cylibs/battle/disengage')
local DisposeBag = require('cylibs/events/dispose_bag')
local Engage = require('cylibs/battle/engage')
local Target = require('cylibs/battle/target')
local GambitTarget = require('cylibs/gambits/gambit_target')
local IsAssistTargetCondition = require('cylibs/conditions/is_assist_target')
local PartyClaimedCondition = require('cylibs/conditions/party_claimed')
local TargetMismatchCondition = require('cylibs/conditions/target_mismatch')
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
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, L{ state.AutoEngageMode, state.AutoPullMode }), Attacker)

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

function Attacker:target_change(target_index)
    Gambiter.target_change(self, target_index)

    self:check_gambits()
end

function Attacker:set_attacker_settings(_)
    local gambit_settings = {
        Gambits = L{
            Gambit.new(GambitTarget.TargetType.Enemy, L{
                GambitCondition.new(StatusCondition.new('Idle'), GambitTarget.TargetType.Self),
                GambitCondition.new(TargetMismatchCondition.new(), GambitTarget.TargetType.Self),
            }, Target.new(), GambitTarget.TargetType.Self),
            Gambit.new(GambitTarget.TargetType.Enemy, L{
                GambitCondition.new(StatusCondition.new('Engaged'), GambitTarget.TargetType.Self),
                GambitCondition.new(TargetMismatchCondition.new(), GambitTarget.TargetType.Self),
            }, Engage.new(), GambitTarget.TargetType.Self),
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
                GambitCondition.new(AggroedCondition.new(), GambitTarget.TargetType.Enemy),
                GambitCondition.new(ConditionalCondition.new(L{ UnclaimedCondition.new(), PartyClaimedCondition.new(true) }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Enemy),
                GambitCondition.new(ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()), GambitTarget.TargetType.Enemy),
            }, Engage.new(), GambitTarget.TargetType.Enemy),
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(ModeCondition.new('AutoEngageMode', 'Mirror'), GambitTarget.TargetType.Self),
                GambitCondition.new(IsAssistTargetCondition.new(), GambitTarget.TargetType.Ally),
                GambitCondition.new(StatusCondition.new('Idle'), GambitTarget.TargetType.Ally),
                GambitCondition.new(StatusCondition.new('Engaged'), GambitTarget.TargetType.Self),
            }, Disengage.new(), GambitTarget.TargetType.Self)
        }
    }

    for gambit in gambit_settings.Gambits:it() do
        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        gambit.conditions = L{
            --GambitCondition.new(ModeCondition.new('AutoPullMode', 'Off'), GambitTarget.TargetType.Self),
        } + gambit.conditions
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
    return conditions:map(function(condition)
        if condition.__type ~= GambitCondition.__type then
            return GambitCondition.new(condition, GambitTarget.TargetType.Self)
        end
        return condition
    end)
end

function Attacker:get_cooldown()
    return 1
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

return Attacker