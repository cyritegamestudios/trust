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

local Gambiter = require('cylibs/trust/roles/gambiter')
local Attacker = setmetatable({}, {__index = Gambiter })
Attacker.__index = Attacker
Attacker.__class = "Attacker"

-- At or above this much TP a new engage goes first even if a song
-- burst is pending: the singer holds its songs at the same threshold,
-- and the held weaponskill is spent before singing resumes. Matches
-- the puller's TP_ENGAGE_PULL_THRESHOLD and the singer's TP hold.
local SONG_HOLD_TP_THRESHOLD = 700

state.AutoEngageMode = M{['description'] = 'Auto Engage Mode', 'Off', 'Always', 'Mirror'}
state.AutoEngageMode:set_description('Off', "Manually engage and disengage.")
state.AutoEngageMode:set_description('Always', "Automatically engage when targeting a claimed mob.")
state.AutoEngageMode:set_description('Mirror', "Mirror the engage status of the party member you are assisting.")

state.AutoDisengageMode = M{['description'] = 'Auto Disengage Mode', 'Off', 'Auto'}
state.AutoDisengageMode:set_description('Off', "Do not disengage when unable to attack a mob.")
state.AutoDisengageMode:set_description('Auto', "Automatically disengage when unable to attack a mob.")

function Attacker.new(action_queue, attacker_settings)
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, L{ state.AutoEngageMode, state.AutoPullMode }), Attacker)

    self.dispose_bag = DisposeBag.new()
    self.num_unable_attack = 0

    self:set_attacker_settings(attacker_settings)

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

    self.dispose_bag:add(WindowerEvents.ActionMessage:addAction(function(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
        if state.AutoDisengageMode.value == 'Off' then
            return
        end
        -- windower.ffxi.get_player() is nil while zoning; action
        -- messages can still arrive in that window.
        local ffxi_player = windower.ffxi.get_player()
        if ffxi_player and actor_id == ffxi_player.id then
            if message_id == 4 or message_id == 5 then
                -- 4: out of range, 5: unable to see
                self.num_unable_attack = self.num_unable_attack + 1
                if self.num_unable_attack > 5 then
                    -- Pass true so a Disengage already queued or
                    -- running is not queued again on every further
                    -- out-of-range message (same identifier).
                    self.action_queue:push_action(Disengage.new():to_action(), true)
                end
            end
        end
    end), WindowerEvents.ActionMessage)
end

function Attacker:target_change(target_index)
    Gambiter.target_change(self, target_index)

    self.num_unable_attack = 0

    self:check_gambits()
end

function Attacker:check_gambits(gambits, param, ignore_delay)
    -- Do not engage a mob in the middle of a song: songs finish
    -- first, then attacking resumes. Same is_singing check the
    -- weaponskill spammer uses. If the player is already engaged,
    -- melee swings continue on their own -- this only holds NEW
    -- engages. On jobs with no Singer role this never holds.
    local main_job = player.trust and player.trust.main_job
    local singer = main_job and main_job:role_with_type("singer")
    if singer and singer.get_is_singing and singer:get_is_singing() then
        return
    end
    -- Also hold while a burst is pending between songs: the singer
    -- goes inactive in the gaps between casts (one action at a time,
    -- with its cooldown between), so the check above alone lets an
    -- engage slip through mid-burst when a claimed or aggroed mob is
    -- already waiting. Songs finish first. At or above the TP
    -- threshold the engage and weaponskill go first, so do not wait
    -- for songs then.
    if singer and singer.has_songs_pending and singer:has_songs_pending() then
        local ffxi_player = windower.ffxi.get_player()
        if not ffxi_player or (ffxi_player.tp or 0) < SONG_HOLD_TP_THRESHOLD then
            return
        end
    end
    return Gambiter.check_gambits(self, gambits, param, ignore_delay)
end

function Attacker:set_attacker_settings(attacker_settings)
    self.engage_distance = attacker_settings.EngageDistance or 30

    local gambit_settings = {
        Gambits = L{
            Gambit.new(GambitTarget.TargetType.Enemy, L{
                GambitCondition.new(ModeCondition.new('AutoEngageMode', 'Always'), GambitTarget.TargetType.Self),
                GambitCondition.new(StatusCondition.new('Idle'), GambitTarget.TargetType.Self),
                GambitCondition.new(MaxDistanceCondition.new(self.engage_distance), GambitTarget.TargetType.Enemy),
                GambitCondition.new(AggroedCondition.new(), GambitTarget.TargetType.Enemy),
                GambitCondition.new(ConditionalCondition.new(L{ UnclaimedCondition.new(), PartyClaimedCondition.new(true) }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Enemy),
                GambitCondition.new(ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()), GambitTarget.TargetType.Enemy),
            }, Engage.new(), GambitTarget.TargetType.Enemy),
            Gambit.new(GambitTarget.TargetType.Enemy, L{
                GambitCondition.new(ModeCondition.new('AutoEngageMode', 'Mirror'), GambitTarget.TargetType.Self),
                GambitCondition.new(IsAssistTargetCondition.new(), GambitTarget.TargetType.Ally),
                GambitCondition.new(StatusCondition.new('Engaged'), GambitTarget.TargetType.Ally),
                GambitCondition.new(StatusCondition.new('Idle'), GambitTarget.TargetType.Self),
                GambitCondition.new(MaxDistanceCondition.new(self.engage_distance), GambitTarget.TargetType.Enemy),
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
                GambitCondition.new(NotCondition.new(L{ ModeCondition.new('AutoEngageMode', 'Off') }), GambitTarget.TargetType.Self),
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

function Attacker:get_default_conditions(gambit)
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