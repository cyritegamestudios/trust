---------------------------
-- Job file for Scholar.
-- @class module
-- @name Scholar

local cure_util = require('cylibs/util/cure_util')

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
    local self = setmetatable(Job.new(), Scholar)

    self.trust_settings = trust_settings
    if self.trust_settings then
        self.cure_settings = trust_settings.CureSettings or cure_util.default_cure_settings
    end

    return self
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
-- Returns the spell that removes the given status effect.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @tparam number num_targets Number of targets afflicted with the status effect
-- @treturn Spell Status removal spell
function Scholar:get_status_removal_spell(debuff_id, num_targets)
    if not self:is_light_arts_active() then return nil end

    local spell_id = cure_util.spell_id_for_debuff_id(debuff_id)
    if spell_id then
        local job_abilities = L{}
        if not self:is_addendum_white_active() then
            job_abilities:append('Addendum: White')
        end
        if num_targets > 1 then
            return Spell.new(res.spells:with('id', spell_id).name, job_abilities:extend(L{'Accession'}))
        else
            return Spell.new(res.spells:with('id', spell_id).name, job_abilities)
        end
    end
    return nil
end

-------
-- Returns the spell that can raise a party member.
-- @treturn Spell Raise spell
function Scholar:get_raise_spell()
    return Buff.new('Raise')
end

-------
-- Returns whether light arts is active.
-- @treturn Boolean True if light arts is active and false otherwise
function Scholar:is_light_arts_active()
    return buff_util.is_buff_active(buff_util.buff_id('Light Arts'))
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
    return buff_util.is_buff_active(buff_util.buff_id('Dark Arts'))
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
function Scholar:get_light_arts_party_buffs()
    return self.trust_settings.LightArts.PartyBuffs
end

-------
-- Returns the list of buffs to cast on the player while in Light Arts.
-- @treturn list List of party buffs
function Scholar:get_light_arts_self_buffs()
    if player_util.get_player_main_job_name_short() == 'SCH' then
        return self.trust_settings.LightArts.SelfBuffs
    else
        return S{}
    end
end

-------
-- Returns the list of buffs to cast on party members while in Dark Arts.
-- @treturn list List of party buffs
function Scholar:get_dark_arts_party_buffs()
    return self.trust_settings.DarkArts.PartyBuffs
end

-------
-- Returns the list of buffs to cast on the player while in Dark Arts.
-- @treturn list List of party buffs
function Scholar:get_dark_arts_self_buffs()
    if player_util.get_player_main_job_name_short() == 'SCH' then
        return self.trust_settings.DarkArts.SelfBuffs
    else
        return S{}
    end
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
-- Returns whether a spell can be cast.
-- @tparam number spell_id Spell id (see spells.lua)
-- @treturn Boolean True if the spell can be cast and false otherwise
function Scholar:can_cast_spell(spell_id)
    if Grimoire.AddendumWhite:contains(res.spells:with('id', spell_id).en) then
        return buff_util.is_buff_active(buff_util.buff_id('Addendum: White'))
    end
    return spell_util.can_cast_spell(spell_id)
end

return Scholar