local ClaimedCondition = require('cylibs/conditions/claimed')
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
    self:set_debuff_settings(debuff_settings)
    return self
end

function Debuffer:set_debuff_settings(debuff_settings)
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
    -- at 500 TP or more, every debuff waits until the weaponskill
    -- has been used and TP drops below 500. (The check runs when
    -- Trust decides to cast, so a cast decided just under 500 can
    -- still land a little past it while the queue clears.) Same
    -- Self-targeted TP check the puller uses for its TP-engage pull.
    conditions:append(GambitCondition.new(NotCondition.new(L{ MinTacticalPointsCondition.new(500) }), GambitTarget.TargetType.Self))
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