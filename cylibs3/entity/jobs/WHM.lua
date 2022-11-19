---------------------------
-- Job file for White Mage.
-- @class module
-- @name White Mage

local Job = require('cylibs/entity/jobs/job')
local WhiteMage = setmetatable({}, {__index = Job })
WhiteMage.__index = WhiteMage

local cure_util = require('cylibs/util/cure_util')

-------
-- Default initializer for a new White Mage.
-- @tparam table cure_settings Cure thresholds
-- @treturn WHM A White Mage
function WhiteMage.new(cure_settings)
    local self = setmetatable(Job.new(), WhiteMage)
    self.cure_settings = cure_settings or cure_util.default_cure_settings
    return self
end

-------
-- Returns the Spell for the cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Cure spell
function WhiteMage:get_cure_spell(hp_missing)
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
function WhiteMage:get_aoe_cure_spell(hp_missing)
    if hp_missing > self.cure_settings.Thresholds['Curaga III'] then
        return Spell.new('Curaga III', L{}, L{})
    elseif hp_missing > self.cure_settings.Thresholds['Curaga II'] then
        return Spell.new('Curaga II', L{}, L{})
    else
        return Spell.new('Curaga', L{}, L{})
    end
end

-------
-- Returns the spell that removes the given status effect.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @tparam number num_targets Number of targets afflicted with the status effect
-- @treturn Spell Status removal spell
function WhiteMage:get_status_removal_spell(debuff_id, num_targets)
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
-- Returns the spell that can raise a party member.
-- @treturn Spell Raise spell
function WhiteMage:get_raise_spell()
    if spell_util.can_cast_spell(spell_util.spell_id('Arise')) then
        return Spell.new('Arise')
    else
        return Buff.new('Raise')
    end
end

return WhiteMage