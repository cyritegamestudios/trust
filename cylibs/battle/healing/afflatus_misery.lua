local buff_util = require('cylibs/util/buff_util')
local cure_util = require('cylibs/util/cure_util')
local spell_util = require('cylibs/util/spell_util')

local AfflatusMisery = {}
AfflatusMisery.__index = AfflatusMisery
AfflatusMisery.__class = "AfflatusMisery"

function AfflatusMisery.new(cure_settings)
    local self = setmetatable({}, AfflatusMisery)
    self:set_cure_settings(cure_settings)
    return self
end

-------
-- Returns the Spell for the cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Cure spell
function AfflatusMisery:get_cure_spell(hp_missing)
    if hp_missing > self.cure_settings.Thresholds['Cure IV'] then
        if not spell_util.is_spell_on_cooldown(res.spells:with('en', 'Cure IV').id) then
            return Spell.new('Cure IV', L{}, L{})
        else
            return Spell.new('Cure V', L{}, L{})
        end
    elseif hp_missing > self.cure_settings.Thresholds['Cure III'] then
        if not spell_util.is_spell_on_cooldown(res.spells:with('en', 'Cure III').id) then
            return Spell.new('Cure III', L{}, L{})
        else
            return Spell.new('Cure IV', L{}, L{})
        end
    else
        if not spell_util.is_spell_on_cooldown(res.spells:with('en', 'Cure II').id) then
            return Spell.new('Cure II', L{}, L{})
        else
            return Spell.new('Cure III', L{}, L{})
        end
    end
end

-------
-- Returns the Spell for the aoe cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Aoe cure spell
function AfflatusMisery:get_aoe_cure_spell(hp_missing)
    if hp_missing > self.cure_settings.Thresholds['Curaga III'] then
        if not spell_util.is_spell_on_cooldown(res.spells:with('en', 'Cura III').id) then
            return Spell.new('Cura III', L{}, L{}, 'me')
        else
            return Spell.new('Cura II', L{}, L{}, 'me')
        end
    elseif hp_missing > self.cure_settings.Thresholds['Curaga II'] then
        if not spell_util.is_spell_on_cooldown(res.spells:with('en', 'Cura II').id) then
            return Spell.new('Cura II', L{}, L{}, 'me')
        else
            return Spell.new('Cura III', L{}, L{}, 'me')
        end
    else
        if not spell_util.is_spell_on_cooldown(res.spells:with('en', 'Cura').id) then
            return Spell.new('Cura', L{}, L{}, 'me')
        else
            return Spell.new('Cura II', L{}, L{}, 'me')
        end
    end
end

-------
-- Returns the spell that removes the given status effect.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @tparam number num_targets Number of targets afflicted with the status effect
-- @treturn Spell Status removal spell
function AfflatusMisery:get_status_removal_spell(debuff_id, num_targets)
    if self.ignore_debuff_ids:contains(debuff_id) then return nil end

    local spell_id = cure_util.spell_id_for_debuff_id(debuff_id)
    if spell_id then
        local spell = res.spells[spell_id]
        if L{ 'Erase', 'Viruna', 'Cursna', 'Blindna', 'Poisona', 'Paralyna' }:contains(spell.name)
                and buff_util.is_buff_active(debuff_id) then
            spell = res.spells[spell_util.spell_id('Esuna')]
        end
        local job_ability_names = L{}
        if not L{ 'Erase', 'Esuna' }:contains(spell.name) and job_util.can_use_job_ability('Divine Caress') then
            job_ability_names:append('Divine Caress')
        end
        return Spell.new(spell.name, job_ability_names)
    end
    return nil
end

-------
-- Returns the delay between status removals.
-- @treturn number Delay between status removals in seconds
function AfflatusMisery:get_status_removal_delay()
    return self.cure_settings.StatusRemovals.Delay or 3
end

-------
-- Sets the cure settings.
-- @tparam T cure_settings Cure settings
function AfflatusMisery:set_cure_settings(cure_settings)
    self.cure_settings = cure_settings or cure_util.default_cure_settings.Magic
    self.ignore_debuff_ids = self.cure_settings.StatusRemovals.Blacklist:map(function(debuff_name) return buff_util.buff_id(debuff_name) end)
end

return AfflatusMisery