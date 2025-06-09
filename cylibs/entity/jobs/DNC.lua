---------------------------
-- Job file for Dancer.
-- @class module
-- @name Dancer

local Job = require('cylibs/entity/jobs/job')
local Dancer = setmetatable({}, {__index = Job })
Dancer.__index = Dancer

local buff_util = require('cylibs/util/buff_util')
local ConditionalCondition = require('cylibs/conditions/conditional')
local cure_util = require('cylibs/util/cure_util')

-------
-- Default initializer for a new Dancer.
-- @tparam T cure_settings Cure thresholds
-- @treturn Dancer A Dancer
function Dancer.new(cure_settings)
    local self = setmetatable(Job.new('DNC'), Dancer)
    self:set_cure_settings(cure_settings)
    return self
end

-------
-- Returns the spell that removes the given status effect.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @tparam number num_targets Number of targets afflicted with the status effect
-- @treturn Spell Status removal spell
function Dancer:get_status_removal_spell(debuff_id, _)
    if self.ignore_debuff_ids:contains(debuff_id) then return nil end

    local spell_id = cure_util.spell_id_for_debuff_id(debuff_id)
    if spell_id then
        local spell_name = spell_util.spell_name(spell_id)
        if S{ 'Erase', 'Paralyna', 'Blindna', 'Poisona', 'Viruna', 'Silena', 'Cursna' }:contains(spell_name) and self:can_perform_waltz('Healing Waltz') then
            return JobAbility.new('Healing Waltz')
        end
    end
    return nil
end

-------
-- Returns the delay between status removals.
-- @treturn number Delay between status removals in seconds
function Dancer:get_status_removal_delay()
    return self.cure_settings.StatusRemovals.Delay or 3
end

-------
-- Returns the spell that can raise a party member.
-- @treturn Spell Raise spell
function Dancer:get_raise_spell()
    return nil
end

-------
-- Sets the cure settings.
-- @tparam T cure_settings Cure settings
function Dancer:set_cure_settings(cure_settings)
    self.cure_settings = cure_settings or cure_util.default_cure_settings.Waltz
    self.ignore_debuff_ids = self.cure_settings.StatusRemovals.Blacklist:map(function(debuff_name) return buff_util.buff_id(debuff_name) end)
end

-------
-- Returns true if the Dancer has at least one finishing move.
-- @treturn boolean True if the Dancer has at least one finishing move
function Dancer:has_finishing_moves()
    return buff_util.is_any_buff_active(L{ 381, 382, 383, 384, 385, 588 })
end

-------
-- Returns true if the Dancer can perform a waltz.
-- @treturn boolean True if the Dancer can perform a waltz
function Dancer:can_perform_waltz(waltz_name)
    local conditions = L{
        NotCondition.new(L{ HasBuffCondition.new('Saber Dance', windower.ffxi.get_player().index) }, windower.ffxi.get_player().index),
        JobAbilityRecastReadyCondition.new(waltz_name),
        MinTacticalPointsCondition.new(res.job_abilities:with('en', waltz_name).tp_cost),
    }
    return Condition.check_conditions(conditions, windower.ffxi.get_player().index)
end

return Dancer