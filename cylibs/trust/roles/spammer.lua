local WeaponSkiller = require('cylibs/trust/roles/weapon_skiller')
local Spammer = setmetatable({}, {__index = WeaponSkiller })
Spammer.__index = Spammer
Spammer.__class = "Spammer"

state.AutoSkillchainMode:set_description('Spam', "Spam weapon skills set with // trust sc spam.")

function Spammer.new(action_queue, weapon_skill_settings)
    local self = setmetatable(WeaponSkiller.new(action_queue, weapon_skill_settings, 'Spam'), Spammer)
    self.conditions = L{}
    self:set_spammer_settings(nil)
    return self
end

-- Menu-adjustable weaponskill holds, from the Combat settings
-- (Trust menu -> Combat -> Config). Defaults reproduce the
-- original fixed behaviour for settings files that predate the
-- keys: save the weaponskill under 3% target HP, hold it while
-- the Bard is singing, and hold it until the player reaches
-- this fight's rolled combat distance. The save cutoff is a
-- preference, not a constant: the HP a mob has left at a given
-- percent depends on the mob, so the right cutoff for locus
-- bats is not the right one for a stronger mob. 0 turns the
-- save off entirely.
function Spammer:set_spammer_settings(combat_settings)
    combat_settings = combat_settings or {}
    self.save_weaponskill_hpp = combat_settings.WeaponSkillSaveHPP or 3
    self.hold_weaponskill_while_singing = combat_settings.WeaponSkillHoldWhileSinging ~= false
    self.hold_weaponskill_for_distance = combat_settings.WeaponSkillHoldForDistance ~= false
end

function Spammer:get_type()
    return "spammer"
end

function Spammer:get_next_ability()
    local player_mob = self:get_party():get_player():get_mob()
    if player_mob == nil then
        return nil
    end
    -- Do not burn 1000 TP on a mob that is about to die from
    -- melee anyway; save the TP for the next mob instead. The
    -- cutoff is the WeaponSkillSaveHPP combat setting.
    local target = self:get_target()
    local target_mob = target and target:get_mob()
    if target_mob and target_mob.hpp and target_mob.hpp < self.save_weaponskill_hpp then
        return nil
    end

    -- Do not weaponskill while the Bard is in the middle of
    -- singing; the song is the priority, and a WS queued during
    -- a song delays the next song in the burst. Can be turned
    -- off with the WeaponSkillHoldWhileSinging combat setting.
    local main_job = player.trust and player.trust.main_job
    local singer = main_job and main_job:role_with_type("singer")
    if self.hold_weaponskill_while_singing and singer and singer.get_is_singing and singer:get_is_singing() then
        return nil
    end

    -- Do not weaponskill into a Nitro burst. Once Nitro has gone
    -- off, the burst finishes before the weaponskill: a weaponskill
    -- landing between the burst's songs puts the next cast in its
    -- action lock ("Unable to cast at this time"). The singer
    -- sings a Nitro burst through below 1000 TP, so this hold
    -- releases the moment the burst completes. Exception: with a
    -- full 1000 TP banked, the weaponskill goes first even
    -- mid-burst -- the singer pauses the burst's songs at 1000 TP
    -- until the weaponskill is spent, so holding here as well
    -- would freeze both until Nitro wears off.
    local ffxi_player = windower.ffxi.get_player()
    if singer and singer.is_nitro_burst_underway and singer:is_nitro_burst_underway()
            and not (ffxi_player and ffxi_player.tp and ffxi_player.tp >= 1000) then
        return nil
    end

    -- Do not weaponskill from out of position. When a mob is
    -- claimed with held TP, CombatMode is still walking the player
    -- to this fight's rolled distance (combat_mode.distance, one
    -- of the random spots under the configured distance). Hold the
    -- weaponskill until the player is there, plus a small
    -- tolerance for the walk settling. Only while CombatMode is
    -- on; mid-fight the player is already at distance, so this
    -- changes nothing there. Can be turned off with the
    -- WeaponSkillHoldForDistance combat setting.
    local combat_mode = main_job and main_job:role_with_type("combatmode")
    if self.hold_weaponskill_for_distance and combat_mode and combat_mode.is_enabled and combat_mode:is_enabled()
            and combat_mode.distance and target_mob and target_mob.distance
            and target_mob.distance:sqrt() > combat_mode.distance + 0.5 then
        return nil
    end

    local default_abilities = L{}

    for skill in self.active_skills:it() do
        local default_ability = skill:get_default_ability()
        if default_ability then
            default_abilities:append(default_ability)
        end
    end

    local all_abilities = self.abilities + default_abilities:filter(function(a)
        return not a:is_aoe()
    end)

    local ability = all_abilities:lastWhere(function(a)
        local all_conditions = L{}:extend(self.conditions):extend(a:get_conditions())
        return Condition.check_conditions(all_conditions, player_mob.index)
    end)
    if ability then
        return ability
    end
    return nil
end

function Spammer:get_delay()
    -- Human-like timing: instead of a fixed 0.25s metronome, the WS
    -- check interval varies from pull to pull, so the weaponskill
    -- lands 1-3s after TP is ready rather than on a fixed beat.
    -- (os.time() ticks in whole seconds, so a 0.5-2.5s delay reads
    -- as a 1-3s pause in practice.)
    return 0.5 + math.random() * 2.0
end

function Spammer:set_conditions(conditions)
    self.conditions = conditions
end

return Spammer