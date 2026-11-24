local WeaponSkiller = require('cylibs/trust/roles/weapon_skiller')
local Spammer = setmetatable({}, {__index = WeaponSkiller })
Spammer.__index = Spammer
Spammer.__class = "Spammer"

state.AutoSkillchainMode:set_description('Spam', "Spam weapon skills set with // trust sc spam.")

function Spammer.new(action_queue, weapon_skill_settings)
    local self = setmetatable(WeaponSkiller.new(action_queue, weapon_skill_settings, 'Spam'), Spammer)
    self.conditions = L{}
    return self
end

function Spammer:get_type()
    return "spammer"
end

function Spammer:get_next_ability()
    -- Do not burn 1000 TP on a mob that is about to die from
    -- melee anyway; save the TP for the next mob instead.
    local target = self:get_target()
    local target_mob = target and target:get_mob()
    if target_mob and target_mob.hpp and target_mob.hpp < 3 then
        return nil
    end

    -- Do not weaponskill while the Bard is in the middle of
    -- singing; the song is the priority, and a WS queued during
    -- a song delays the next song in the burst.
    local main_job = player.trust and player.trust.main_job
    local singer = main_job and main_job:role_with_type("singer")
    if singer and singer.get_is_singing and singer:get_is_singing() then
        return nil
    end

    -- Do not weaponskill from out of position. When a mob is
    -- claimed with held TP, CombatMode is still walking the player
    -- to this fight's rolled distance (combat_mode.distance, one
    -- of the random spots under the configured distance). Hold the
    -- weaponskill until the player is there, plus a small
    -- tolerance for the walk settling. Only while CombatMode is
    -- on; mid-fight the player is already at distance, so this
    -- changes nothing there.
    local combat_mode = main_job and main_job:role_with_type("combatmode")
    if combat_mode and combat_mode.is_enabled and combat_mode:is_enabled()
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
        return Condition.check_conditions(all_conditions, self:get_party():get_player():get_mob().index)
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