local buff_util = require('cylibs/util/buff_util')
local cure_util = require('cylibs/util/cure_util')
local spell_util = require('cylibs/util/spell_util')
local Spell = require('cylibs/battle/spell')

local AfflatusSolace = {}
AfflatusSolace.__index = AfflatusSolace
AfflatusSolace.__class = "AfflatusSolace"

function AfflatusSolace.new(cure_settings)
    local self = setmetatable({}, AfflatusSolace)
    self:set_cure_settings(cure_settings)
    return self
end

-------
-- Returns the Spell for the cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Cure spell
function AfflatusSolace:get_cure_spell(hp_missing)
    if self:is_afflatus_solace_active() and self:is_overcure_enabled() then
        hp_missing = hp_missing * 1.5
    end

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
function AfflatusSolace:get_aoe_cure_spell(hp_missing)
    if hp_missing > self.cure_settings.Thresholds['Curaga III'] then
        if not spell_util.is_spell_on_cooldown(res.spells:with('en', 'Curaga III').id) then
            return Spell.new('Curaga III', L{}, L{})
        else
            return Spell.new('Curaga IV', L{}, L{})
        end
    elseif hp_missing > self.cure_settings.Thresholds['Curaga II'] then
        if not spell_util.is_spell_on_cooldown(res.spells:with('en', 'Curaga II').id) then
            return Spell.new('Curaga II', L{}, L{})
        else
            return Spell.new('Curaga III', L{}, L{})
        end
    else
        if not spell_util.is_spell_on_cooldown(res.spells:with('en', 'Curaga').id) then
            return Spell.new('Curaga', L{}, L{})
        else
            return Spell.new('Curaga II', L{}, L{})
        end
    end
end

-------
-- Returns the spell that removes the given status effect.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @tparam number num_targets Number of targets afflicted with the status effect
-- @treturn Spell Status removal spell
function AfflatusSolace:get_status_removal_spell(debuff_id, num_targets)
    if self.ignore_debuff_ids:contains(debuff_id) or self.ignore_debuff_names:contains(buff_util.buff_name(debuff_id)) then return nil end

    local spell_id = cure_util.spell_id_for_debuff_id(debuff_id)
    if spell_id then
        local job_ability_names = L{}
        if not spell_util.spell_name(spell_id) == 'Erase' and job_util.can_use_job_ability('Divine Caress') then
            job_ability_names:append('Divine Caress')
        end
        return Spell.new(res.spells:with('id', spell_id).en, job_ability_names)
    end
    return nil
end

-------
-- Returns the delay between status removals.
-- @treturn number Delay between status removals in seconds
function AfflatusSolace:get_status_removal_delay()
    return self.cure_settings.StatusRemovals.Delay or 3
end

-------
-- Returns a cluster of party members within 10' of the first party member in the list.
-- @tparam list List of party members
-- @treturn list List of party members
function AfflatusSolace:get_cure_cluster(party_members)
    local spell_target = party_members[1]
    party_members = party_members:filter(function(party_member)
        local distance = geometry_util.distance(spell_target:get_mob(), party_member:get_mob())
        return distance < 10
    end)
    return party_members
end

-------
-- Returns if Afflatus Solace is active
-- @treturn Boolean True if Afflatus Solace is active
function AfflatusSolace:is_afflatus_solace_active()
    return buff_util.is_buff_active(buff_util.buff_id('Afflatus Solace'))
end

-------
-- Returns if overcure is enabled
-- @treturn Boolean if overcure is enabled
function AfflatusSolace:is_overcure_enabled()
    return self.cure_settings.Thresholds['Overcure'] or false
end

-------
-- Sets the cure settings.
-- @tparam T cure_settings Cure settings
function AfflatusSolace:set_cure_settings(cure_settings)
    self.cure_settings = cure_settings or cure_util.default_cure_settings.Magic
    self.ignore_debuff_ids = self.cure_settings.StatusRemovals.Blacklist:map(function(debuff_name) return buff_util.buff_id(debuff_name) end)
    self.ignore_debuff_names = self.cure_settings.StatusRemovals.Blacklist
end

return AfflatusSolace