---------------------------
-- Job file for White Mage.
-- @class module
-- @name White Mage

local Job = require('cylibs/entity/jobs/job')
local WhiteMage = setmetatable({}, {__index = Job })
WhiteMage.__index = WhiteMage

local buff_util = require('cylibs/util/buff_util')
local cure_util = require('cylibs/util/cure_util')
local spell_util = require('cylibs/util/spell_util')

-------
-- Default initializer for a new White Mage.
-- @tparam T cure_settings Cure thresholds
-- @treturn WHM A White Mage
function WhiteMage.new(cure_settings)
    local self = setmetatable(Job.new(), WhiteMage)
    self:set_cure_settings(cure_settings)
    return self
end

-------
-- Returns the Spell for the cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Cure spell
function WhiteMage:get_cure_spell(hp_missing)
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
function WhiteMage:get_aoe_cure_spell(hp_missing)
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
function WhiteMage:get_status_removal_spell(debuff_id, num_targets)
    if self.ignore_debuff_ids:contains(debuff_id) then return nil end

    local spell_id = cure_util.spell_id_for_debuff_id(debuff_id)
    if spell_id then
        local job_ability_names = L{}
        if not spell_util.spell_name(spell_id) == 'Erase' and job_util.can_use_job_ability('Divine Caress') then
            job_ability_names:append('Divine Caress')
        end
        return Spell.new(res.spells:with('id', spell_id).name, job_ability_names)
    end
    return nil
end

-------
-- Returns the delay between status removals.
-- @treturn number Delay between status removals in seconds
function WhiteMage:get_status_removal_delay()
    return self.cure_settings.StatusRemovals.Delay or 3
end

-------
-- Returns the spell that can raise a party member.
-- @treturn Spell Raise spell
function WhiteMage:get_raise_spell()
    if spell_util.can_cast_spell(spell_util.spell_id('Arise')) then
        return Spell.new('Arise')
    else
        return Buff.new('Raise')
    end
end

-------
-- Returns all AOE spells.
-- @treturn list List of AOE spell names
function WhiteMage:get_aoe_spells()
    return L{ 'Banishga', 'Banishga II', 'Diaga' }
end

-------
-- Returns the threshold below which players should be healed.
-- @tparam Boolean is_backup_healer Whether the player is the backup healer
-- @treturn number HP percentage
function WhiteMage:get_cure_threshold(is_backup_healer)
    if is_backup_healer then
        return self.cure_settings.Thresholds['Emergency'] or 25
    else
        return self.cure_settings.Thresholds['Default'] or 78
    end
end

-------
-- Returns the delay between cures.
-- @treturn number Delay between cures in seconds
function WhiteMage:get_cure_delay()
    return self.cure_settings.Delay or 2
end

-------
-- Returns if overcure is enabled
-- @treturn Boolean if overcure is enabled
function WhiteMage:is_overcure_enabled()
    return self.cure_settings.Thresholds['Overcure'] or false
end

-------
-- Returns if Afflatus Solace is active
-- @treturn Boolean True if Afflatus Solace is active
function WhiteMage:is_afflatus_solace_active()
    return buff_util.is_buff_active(buff_util.buff_id('Afflatus Solace'))
end

-------
-- Sets the cure settings.
-- @tparam T cure_settings Cure settings
function WhiteMage:set_cure_settings(cure_settings)
    self.cure_settings = cure_settings or cure_util.default_cure_settings.Magic
    self.ignore_debuff_ids = self.cure_settings.StatusRemovals.Blacklist:map(function(debuff_name) return buff_util.buff_id(debuff_name) end)
end

return WhiteMage