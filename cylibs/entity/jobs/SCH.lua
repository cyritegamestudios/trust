---------------------------
-- Job file for Scholar.
-- @class module
-- @name Scholar

local cure_util = require('cylibs/util/cure_util')
local SpellList = require('cylibs/util/spell_list')

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
    self.allow_sub_job = trust_settings.AllowSubJob
    if self.allow_sub_job == nil then
        self.allow_sub_job = true
    end
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
-- Returns the maximum number of strategems.
-- @treturn number Number of strategems
function Scholar:get_max_num_strategems()
    return math.floor((self:getLevel() + 10) / 20)
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

-------
-- Returns spells only available with Addendum: White.
-- @treturn list List of spell names.
function Scholar:get_addendum_white_spells()
    return L{
        'Poisona', 'Paralyna', 'Blindna', 'Silena', 'Cursna', 'Reraise',
        'Erase', 'Viruna', 'Stona', 'Raise II', 'Reraise II', 'Raise III',
        'Reraise III',
    }
end

-------
-- Returns spells only available with Addendum: Black.
-- @treturn list List of spell names.
function Scholar:get_addendum_black_spells()
    return L{
        'Sleep', 'Dispel', 'Sleep II', 'Stone IV', 'Water IV', 'Aero IV',
        'Fire IV', 'Blizzard IV', 'Thunder IV', 'Stone V', 'Water V', 'Aero V',
        'Break', 'Fire V', 'Blizzard V', 'Thunder V',
    }
end

-------
-- Returns a list of conditions for an ability.
-- @tparam Spell|JobAbility ability The ability
-- @treturn list List of conditions
function Scholar:get_conditions_for_ability(ability)
    local conditions = Job.get_conditions_for_ability(self, ability) + ability:get_conditions()
    if ability.requires_all_job_abilities ~= nil and ability:requires_all_job_abilities() then
        local strategem_count = 0
        for job_ability_name in ability:get_job_abilities():it() do
            local job_ability = JobAbility.new(job_ability_name)
            if job_ability:get_job_ability().type == 'Scholar' then
                strategem_count = strategem_count + 1
            else
                conditions = conditions + job_ability:get_conditions()
            end
        end
        if strategem_count > 0 then
            conditions:append(StrategemCountCondition.new(strategem_count, Condition.Operator.GreaterThanOrEqualTo))
        end
    end
    if self:get_addendum_white_spells():contains(ability:get_name()) then
        conditions:append(HasBuffCondition.new('Addendum: White', windower.ffxi.get_player().index))
    elseif self:get_addendum_black_spells():contains(ability:get_name()) then
        conditions:append(HasBuffCondition.new('Addendum: Black', windower.ffxi.get_player().index))
    end
    return conditions
end

return Scholar