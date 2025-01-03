---------------------------
-- Job file for Scholar.
-- @class module
-- @name Scholar

local cure_util = require('cylibs/util/cure_util')
local SpellList = require('cylibs/util/spell_list')
local StatusRemoval = require('cylibs/battle/healing/status_removal')

local Job = require('cylibs/entity/jobs/job')
local Scholar = setmetatable({}, {__index = Job })
Scholar.__index = Scholar

-- Grimoire specific spells
local Grimoire = {
    AddendumWhite = L{ 'Poisona', 'Paralyna', 'Blindna', 'Silena', 'Cursna', 'Reraise', 'Erase', 'Viruna', 'Stona', 'Raise III', 'Reraise III' }
}

-------
-- Default initializer for a new Scholar.
-- @tparam T trust_settings Trust settings
-- @treturn SCH A Scholar
function Scholar.new(trust_settings)
    local self = setmetatable(Job.new('SCH', L{ 'Dispelga', 'Impact' }), Scholar)
    self:set_trust_settings(trust_settings)
    self.allow_sub_job = trust_settings.AllowSubJob
    if self.allow_sub_job == nil then
        self.allow_sub_job = true
    end
    self.ignore_debuff_ids = self.cure_settings.StatusRemovals.Blacklist:map(function(debuff_name) return res.buffs:with('en', debuff_name).id end)
    self.sub_job_spell_list = SpellList.new(windower.ffxi.get_player().sub_job_id, windower.ffxi.get_player().sub_job_level, L{})
    return self
end

-------
-- Returns a list of known spell ids. For SCH only, sub job spells are returned as well.
-- @tparam function filter Optional filter function
-- @treturn list List of known spell ids
function Scholar:get_spells(filter)
    filter = filter or function(_) return true end
    local spells = Job.get_spells(self, filter)
    if self:isMainJob() then
        self.sub_job_spell_list.jobLevel = windower.ffxi.get_player().sub_job_level
        spells = spells + self.sub_job_spell_list:getKnownSpellIds():filter(function(spell_id)
            return filter(spell_id)
        end)
    end
    return spells
end

-------
-- Returns the Spell for the cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Cure spell
function Scholar:get_cure_spell(hp_missing)
    if hp_missing > self.cure_settings.Thresholds['Cure IV'] then
        return Spell.new('Cure IV', L{}, L{})
    elseif hp_missing > self.cure_settings.Thresholds['Cure III'] then
        return Spell.new('Cure III', L{}, L{})
    else
        return Spell.new('Cure II', L{}, L{})
    end
end

-------
-- Returns the Spell for the aoe cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Aoe cure spell
function Scholar:get_aoe_cure_spell(hp_missing)
    if hp_missing > self.cure_settings.Thresholds['Cure IV'] then
        return Spell.new('Cure III', L{'Accession'})
    end
    return nil
end

-------
-- Returns the threshold below which players should be healed.
-- @tparam Boolean is_backup_healer Whether the player is the backup healer
-- @treturn number HP percentage
function Scholar:get_cure_threshold(is_backup_healer)
    if is_backup_healer then
        return self.cure_settings.Thresholds['Emergency'] or 25
    else
        return self.cure_settings.Thresholds['Default'] or 78
    end
end

-------
-- Returns the threshold above which AOE cures should be used.
-- @treturn number Minimum number of party members under cure threshold
function Scholar:get_aoe_threshold()
    return self.cure_settings.MinNumAOETargets or 3
end

-------
-- Returns the delay between cures.
-- @tparam boolean is_backup_healer Whether the player is the backup healer
-- @treturn number Delay between cures in seconds
function Scholar:get_cure_delay(is_backup_healer)
    if is_backup_healer then
        return self.cure_settings.Delay or 2
    else
        return 0
    end
end

-------
-- Returns the spell that removes the given status effect.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @tparam number num_targets Number of targets afflicted with the status effect
-- @treturn Spell Status removal spell
function Scholar:get_status_removal_spell(debuff_id, num_targets)
    if self.ignore_debuff_ids:contains(debuff_id) then return end

    if not self:is_light_arts_active() then return nil end

    local spell_id = cure_util.spell_id_for_debuff_id(debuff_id)
    if spell_id then
        local job_abilities = L{}
        if not self:is_addendum_white_active() then
            job_abilities:append('Addendum: White')
        end
        if num_targets > 1 then
            return StatusRemoval.new(res.spells:with('id', spell_id).en, job_abilities:extend(L{'Accession'}), debuff_id)
        else
            return StatusRemoval.new(res.spells:with('id', spell_id).en, job_abilities, debuff_id)
        end
    end
    return nil
end

-------
-- Returns the delay between status removals.
-- @treturn number Delay between status removals in seconds
function Scholar:get_status_removal_delay()
    return self.cure_settings.StatusRemovals.Delay or 3
end

-------
-- Returns the spell that can raise a party member.
-- @treturn Spell Raise spell
function Scholar:get_raise_spell()
    return Buff.new('Raise')
end

-------
-- Returns all AOE spells.
-- @treturn list List of AOE spell names
function Scholar:get_aoe_spells()
    return L{}
end

-------
-- Returns whether light arts is active.
-- @treturn Boolean True if light arts is active and false otherwise
function Scholar:is_light_arts_active()
    return buff_util.is_buff_active(buff_util.buff_id('Light Arts')) or self:is_addendum_white_active()
end

-------
-- Returns whether Addendum: White is active.
-- @treturn Boolean True if Addendum: White is active and false otherwise
function Scholar:is_addendum_white_active()
    return buff_util.is_buff_active(buff_util.buff_id('Addendum: White'))
end

-------
-- Returns whether dark arts is active.
-- @treturn Boolean True if dark arts is active and false otherwise
function Scholar:is_dark_arts_active()
    return buff_util.is_buff_active(buff_util.buff_id('Dark Arts')) or self:is_addendum_black_active()
end

-------
-- Returns whether Addendum: Black is active.
-- @treturn Boolean True if Addendum: Black is active and false otherwise
function Scholar:is_addendum_black_active()
    return buff_util.is_buff_active(buff_util.buff_id('Addendum: Black'))
end

-------
-- Returns the list of buffs to cast on party members while in Light Arts.
-- @treturn list List of party buffs
function Scholar:get_light_arts_buffs()
    return self.trust_settings.LightArts.BuffSettings
end


-------
-- Returns the list of buffs to cast on party members while in Dark Arts.
-- @treturn list List of party buffs
function Scholar:get_dark_arts_buffs()
    return self.trust_settings.DarkArts.BuffSettings
end

-------
-- Returns whether the player has sublimation active.
-- @treturn Boolean True is sublimation is active and false otherwise
function Scholar:is_sublimation_active()
    local player_buffs = L(windower.ffxi.get_player().buffs)
    return buff_util.is_buff_active(buff_util.buff_id('Sublimation: Activated'), player_buffs)
            or buff_util.is_buff_active(buff_util.buff_id('Sublimation: Complete'), player_buffs)
end

-------
-- Returns the current number of strategems remaining.
-- @treturn number Number of strategems
function Scholar:get_current_num_strategems()
    return player_util.get_current_strategem_count()
end

-------
-- Returns whether a spell can be cast.
-- @tparam number spell_id Spell id (see spells.lua)
-- @treturn Boolean True if the spell can be cast and false otherwise
function Scholar:can_cast_spell(spell_id)
    if Grimoire.AddendumWhite:contains(res.spells:with('id', spell_id).en) then
        return buff_util.is_buff_active(buff_util.buff_id('Addendum: White'))
    end
    return spell_util.can_cast_spell(spell_id)
end

-------
-- Sets the trust settings.
-- @tparam T trust_settings Trust settings
function Scholar:set_trust_settings(trust_settings)
    self.trust_settings = trust_settings
    self.cure_settings = trust_settings.CureSettings or cure_util.default_cure_settings.Magic
end

-------
-- Returns the highest tier storm spell for the given element.
-- @tparam string element Element (e.g. earth, lightning)
-- @treturn Buff Buff for storm
function Scholar:get_storm(element)
    local element_to_storm = {
        Fire = 'Firestorm',
        Ice = 'Hailstorm',
        Wind = 'Windstorm',
        Earth = 'Sandstorm',
        Lightning = 'Thunderstorm',
        Water = 'Rainstorm',
        Light = 'Aurorastorm',
        Dark = 'Voidstorm',
    }
    local storm_name = element_to_storm[element:gsub("^%l", string.upper)]
    if storm_name then
        if spell_util.knows_spell(spell_util.spell_id(storm_name.." II")) then
            return Spell.new(storm_name.." II")
        else
            return Spell.new(storm_name)
        end
    end
    return nil
end

-------
-- Returns all storm names (e.g. Hailstorm II).
-- @treturn list List of storm names.
function Scholar:get_all_storm_names()
    return L{
        'Firestorm II', 'Hailstorm II', 'Windstorm II', 'Sandstorm II',
        'Thunderstorm II', 'Rainstorm II', 'Aurorastorm II', 'Voidstorm II'
    }
end

return Scholar