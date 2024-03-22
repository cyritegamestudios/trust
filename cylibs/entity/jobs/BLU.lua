---------------------------
-- Job file for Blue Mage.
-- @class module
-- @name BlueMage

local buff_util = require('cylibs/util/buff_util')
local cure_util = require('cylibs/util/cure_util')

local Job = require('cylibs/entity/jobs/job')
local BlueMage = setmetatable({}, {__index = Job })
BlueMage.__index = BlueMage

-------
-- Default initializer for a new Blue Mage.
-- @tparam T cure_settings Cure thresholds
-- @treturn BLU A Blue Mage
function BlueMage.new(cure_settings)
    local self = setmetatable(Job.new(), BlueMage)
    self:set_cure_settings(cure_settings)
    return self
end

-------
-- Returns whether a given spell is currently equipped.
-- @tparam string spell_name Spell name (see res/spells.lua)
-- @treturn boolean True if the spell is equipped, false otherwise
function BlueMage:has_spell_equipped(spell_name)
    local spells = windower.ffxi.get_mjob_data().spells
    for _, spell_id in pairs(spells) do
        if spell_id == spell_util.spell_id(spell_name) then
            return true
        end
    end
    return false
end

-------
-- Returns the JobAbility for the cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn JobAbility Job ability
function BlueMage:get_cure_spell(hp_missing)
    if hp_missing > self.cure_settings.Thresholds['Cure IV'] then
        if not spell_util.is_spell_on_cooldown(res.spells:with('en', 'Magic Fruit').id) then
            return Spell.new('Magic Fruit', L{}, L{})
        else
            return Spell.new('White Wind', L{}, L{}, 'me')
        end
    elseif hp_missing > self.cure_settings.Thresholds['Cure III'] then
        if not spell_util.is_spell_on_cooldown(res.spells:with('en', 'Magic Fruit').id) then
            return Spell.new('Magic Fruit', L{}, L{})
        else
            return Spell.new('Wild Carrot', L{}, L{})
        end
    else
        return Spell.new('White Wind', L{}, L{}, 'me')
    end
end

-------
-- Returns the JobAbility for the aoe cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn JobAbility Aoe job ability
function BlueMage:get_aoe_cure_spell(hp_missing)
    if hp_missing > self.cure_settings.Thresholds['Curaga III'] then
        if not spell_util.is_spell_on_cooldown(res.spells:with('en', 'White Wind').id) then
            return Spell.new('White Wind', L{}, L{}, 'me')
        else
            return Spell.new('Healing Breeze', L{}, L{}, 'me')
        end
    elseif hp_missing > self.cure_settings.Thresholds['Curaga II'] then
        if not spell_util.is_spell_on_cooldown(res.spells:with('en', 'Healing Breeze').id) then
            return Spell.new('Healing Breeze', L{}, L{}, 'me')
        else
            return Spell.new('White Wind', L{}, L{}, 'me')
        end
    else
        return Spell.new('Healing Breeze', L{}, L{}, 'me')
    end
end

-------
-- Returns the threshold above which AOE cures should be used.
-- @treturn number Minimum number of party members under cure threshold
function BlueMage:get_aoe_threshold()
    return self.cure_settings.MinNumAOETargets or 3
end

-------
-- Returns the spell that removes the given status effect.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @tparam number num_targets Number of targets afflicted with the status effect
-- @treturn Spell Status removal spell
function BlueMage:get_status_removal_spell(debuff_id, num_targets)
    if self.ignore_debuff_ids:contains(debuff_id) or self.ignore_debuff_names:contains(buff_util.buff_name(debuff_id)) then return nil end

    local spell_id = cure_util.spell_id_for_debuff_id(debuff_id)
    if spell_id then
        if spell_util.spell_name(spell_id) == 'Erase' then
            return Spell.new('Winds of Promy.')
        end
    end
    return nil
end

-------
-- Returns the delay between status removals.
-- @treturn number Delay between status removals in seconds
function BlueMage:get_status_removal_delay()
    return self.cure_settings.StatusRemovals.Delay or 3
end

-------
-- Returns the spell that can raise a party member.
-- @treturn Spell Raise spell
function BlueMage:get_raise_spell()
    return nil
end

-------
-- Returns the threshold below which players should be healed.
-- @tparam Boolean is_backup_healer Whether the player is the backup healer
-- @treturn number HP percentage
function BlueMage:get_cure_threshold(is_backup_healer)
    if is_backup_healer then
        return self.cure_settings.Thresholds['Emergency'] or 25
    else
        return self.cure_settings.Thresholds['Default'] or 78
    end
end

-------
-- Returns the delay between cures.
-- @treturn number Delay between cures in seconds
function BlueMage:get_cure_delay()
    return self.cure_settings.Delay or 2
end

-------
-- Sets the cure settings.
-- @tparam T cure_settings Cure settings
function BlueMage:set_cure_settings(cure_settings)
    self.cure_settings = cure_settings or cure_util.default_cure_settings.Magic
    self.ignore_debuff_ids = self.cure_settings.StatusRemovals.Blacklist:map(function(debuff_name) return buff_util.buff_id(debuff_name) end)
end

return BlueMage