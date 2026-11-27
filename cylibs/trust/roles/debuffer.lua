local ClaimedCondition = require('cylibs/conditions/claimed')
local DisposeBag = require('cylibs/events/dispose_bag')
local GambitTarget = require('cylibs/gambits/gambit_target')
local ImmuneCondition = require('cylibs/conditions/immune')
local MinHitPointsPercentCondition = require('cylibs/conditions/min_hpp')
local MinTacticalPointsCondition = require('cylibs/conditions/min_tp')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Debuffer = setmetatable({}, {__index = Gambiter })
Debuffer.__index = Debuffer
Debuffer.__class = "Debuffer"

state.AutoDebuffMode = M{['description'] = 'Debuff Enemies', 'Off', 'Auto'}
state.AutoDebuffMode:set_description('Auto', "Automatically debuff a mob.")

state.AutoSilenceMode = M{['description'] = 'Silence Casters', 'Off', 'Auto'}
state.AutoSilenceMode:set_description('Auto', "Automatically silence mobs after they cast a spell.")

function Debuffer.new(action_queue, debuff_settings, job)
    local self = setmetatable(Gambiter.new(action_queue, {}, state.AutoDebuffMode), Debuffer)
    self.job = job
    self.last_weaponskill_time = 0
    self.dispose_bag = DisposeBag.new()
    self:set_debuff_settings(debuff_settings)
    return self
end

function Debuffer:destroy()
    Gambiter.destroy(self)

    self.dispose_bag:destroy()
end

function Debuffer:on_add()
    Gambiter.on_add(self)

    -- Remember when the player's weaponskill lands (action packet
    -- category 3) so check_gambits can hold debuffs for 2 seconds
    -- after it: a cast sent inside the weaponskill's action lock is
    -- rejected with "Unable to cast at this time". That is exactly
    -- when the TP hold releases -- the weaponskill spends the TP the
    -- debuffs were waiting on -- so Foe Requiem right after a Savage
    -- Blade was the usual victim.
    self.dispose_bag:add(WindowerEvents.Action:addAction(function(act)
        local player = windower.ffxi.get_player()
        if player and act.actor_id == player.id and act.category == 3 then
            self.last_weaponskill_time = os.clock()
        end
    end), WindowerEvents.Action)
end

function Debuffer:set_debuff_settings(debuff_settings)
    self.debuff_settings = debuff_settings
    for gambit in debuff_settings.Gambits:it() do
        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = self:get_default_conditions(gambit)
        for condition in conditions:it() do
            condition:set_editable(condition.__type == NumResistsCondition.__type)
            gambit:addCondition(condition)
        end
    end
    self:set_gambit_settings(debuff_settings)
end

-- Menu-adjustable debuff hold, from the Combat settings (Trust
-- menu -> Combat -> Config -> Debuff Hold TP). At or above this
-- much TP debuffs wait for the weaponskill. The default
-- reproduces the fixed 500 hold for settings files that predate
-- the key. Changing it rebuilds the gambit conditions.
function Debuffer:set_combat_settings(combat_settings)
    combat_settings = combat_settings or {}
    self.debuff_hold_tp = combat_settings.DebuffHoldTP or 500
    if self.debuff_settings then
        self:set_debuff_settings(self.debuff_settings)
    end
end

function Debuffer:get_default_conditions(gambit)
    local conditions = L{
        ClaimedCondition.new(),
        NotCondition.new(L{ HasDebuffCondition.new(gambit:getAbility():get_status().en) }),
        NotCondition.new(L{ ImmuneCondition.new(gambit:getAbility():get_name()) }),
        NumResistsCondition.new(gambit:getAbility():get_name(), Condition.Operator.LessThan, 4),
        -- Do not waste a debuff cast on a mob that is about to
        -- die; a 2s Requiem on a mob at 15% HP lands just as
        -- melee finishes it.
        MinHitPointsPercentCondition.new(15),
    }
    -- Hold debuffs while the player is saving TP for a weaponskill:
    -- at the Debuff Hold TP line (Combat settings, default 500) or
    -- more, every debuff waits until the weaponskill has been used
    -- and TP drops below the line. (The check runs when Trust
    -- decides to cast, so a cast decided just under the line can
    -- still land a little past it while the queue clears.) Same
    -- Self-targeted TP check the puller uses for its TP-engage pull.
    conditions:append(GambitCondition.new(NotCondition.new(L{ MinTacticalPointsCondition.new(self.debuff_hold_tp or 500) }), GambitTarget.TargetType.Self))
    return conditions + self.job:get_conditions_for_ability(gambit:getAbility()):map(function(condition)
        return GambitCondition.new(condition, GambitTarget.TargetType.Self)
    end)
end

function Debuffer:check_gambits(gambits, param, ignore_delay)
    -- Do not debuff in the middle of a song. Same is_singing check
    -- the weaponskill spammer uses: while the Singer is mid-burst a
    -- debuff cast would only queue behind the songs, so hold all
    -- debuffs until the burst finishes. Checked before the
    -- Gambiter's cooldown bookkeeping so the debuffer retries on
    -- the next tic once singing stops. On jobs with no Singer role
    -- this never holds.
    -- The is_singing check alone is not enough: between the songs
    -- of a burst the singer is briefly not casting (it queues one
    -- song at a time), so a debuff -- Foe Requiem is the one that
    -- kept slipping through -- could start in the gap and interrupt
    -- the burst. has_songs_pending() covers the whole burst, gaps
    -- included, the same check the puller and attacker already use
    -- to stay out of the singer's way. At 500+ TP the debuffs are
    -- held by the TP condition anyway, so this changes nothing
    -- about the weaponskill-first order.
    local main_job = player.trust and player.trust.main_job
    local singer = main_job and main_job:role_with_type("singer")
    if singer and singer.get_is_singing and singer:get_is_singing() then
        return
    end
    if singer and singer.has_songs_pending and singer:has_songs_pending() then
        return
    end
    -- Hold debuffs for 2 seconds after the player's weaponskill (see
    -- on_add): a cast sent in that window hits the weaponskill's
    -- action lock and fails with "Unable to cast at this time". The
    -- debuffer retries on the next tic once the lock has passed.
    -- This role is shared by every job, so the wait applies to all
    -- jobs that debuff.
    if self.last_weaponskill_time and os.clock() - self.last_weaponskill_time < 2 then
        return
    end
    return Gambiter.check_gambits(self, gambits, param, ignore_delay)
end

function Debuffer:allows_duplicates()
    return true
end

function Debuffer:get_type()
    return "debuffer"
end

function Debuffer:get_cooldown()
    return 6
end

function Debuffer:tostring()
    return localization_util.commas(self.gambits:map(function(gambit)
        return gambit:tostring()
    end), 'and')
end

return Debuffer