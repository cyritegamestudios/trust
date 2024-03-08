---------------------------
-- Job file for White Mage.
-- @class module
-- @name White Mage

local Job = require('cylibs/entity/jobs/job')
local WhiteMage = setmetatable({}, {__index = Job })
WhiteMage.__index = WhiteMage

local AfflatusMisery = require('cylibs/battle/healing/afflatus_misery')
local AfflatusSolace = require('cylibs/battle/healing/afflatus_solace')
local buff_util = require('cylibs/util/buff_util')
local cure_util = require('cylibs/util/cure_util')
local spell_util = require('cylibs/util/spell_util')

WhiteMage.Afflatus = {}
WhiteMage.Afflatus.Solace = "AfflatusSolace"
WhiteMage.Afflatus.Misery = "AfflatusMisery"

-------
-- Default initializer for a new White Mage.
-- @tparam T cure_settings Cure thresholds
-- @tparam string afflatus_mode Afflatus Solace or Afflatus Misery
-- @treturn WHM A White Mage
function WhiteMage.new(cure_settings, afflatus_mode)
    local self = setmetatable(Job.new(), WhiteMage)
    self:set_cure_settings(cure_settings)
    self:set_afflatus_mode(afflatus_mode or self:get_afflatus_mode())
    return self
end

-------
-- Returns the Spell for the cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Cure spell
function WhiteMage:get_cure_spell(hp_missing)
    return self.current_afflatus:get_cure_spell(hp_missing)
end

-------
-- Returns the Spell for the aoe cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Aoe cure spell
function WhiteMage:get_aoe_cure_spell(hp_missing)
    return self.current_afflatus:get_aoe_cure_spell(hp_missing)
end

-------
-- Returns the spell that removes the given status effect.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @tparam number num_targets Number of targets afflicted with the status effect
-- @treturn Spell Status removal spell
function WhiteMage:get_status_removal_spell(debuff_id, num_targets)
    return self.current_afflatus:get_status_removal_spell(debuff_id, num_targets)
end

-------
-- Returns the delay between status removals.
-- @treturn number Delay between status removals in seconds
function WhiteMage:get_status_removal_delay()
    return self.current_afflatus:get_status_removal_delay()
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
-- Returns a cluster of party members within 10' of the first party member in the list.
-- @tparam list List of party members
-- @treturn list List of party members
function WhiteMage:get_cure_cluster(party_members)
    return self.current_afflatus:get_cure_cluster(party_members)
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
-- Returns the threshold above which AOE cures should be used.
-- @treturn number Minimum number of party members under cure threshold
function WhiteMage:get_aoe_threshold()
    return self.cure_settings.MinNumAOETargets or 3
end

-------
-- Returns the delay between cures.
-- @treturn number Delay between cures in seconds
function WhiteMage:get_cure_delay()
    return self.cure_settings.Delay or 2
end

-------
-- Sets the cure settings.
-- @tparam T cure_settings Cure settings
function WhiteMage:set_cure_settings(cure_settings)
    self.cure_settings = cure_settings or cure_util.default_cure_settings.Magic
    self.ignore_debuff_ids = self.cure_settings.StatusRemovals.Blacklist:map(function(debuff_name) return buff_util.buff_id(debuff_name) end)
end

-------
-- Sets the cure settings.
-- @tparam T cure_settings Cure settings
-- @tparam string afflatus_mode Afflatus Solace or Afflatus Misery
function WhiteMage:set_afflatus_mode(afflatus_mode)
    if self.afflatus_mode == afflatus_mode then
        return
    end
    self.afflatus_mode = afflatus_mode

    if self.afflatus_mode == WhiteMage.Afflatus.Misery then
        self.current_afflatus = AfflatusMisery.new(self.cure_settings)
    else
        self.current_afflatus = AfflatusSolace.new(self.cure_settings)
    end
end

-------
-- Returns the current afflatus mode.
-- @treturn WhiteMage.Afflatus Afflatus Solace or Afflatus Misery
function WhiteMage:get_afflatus_mode()
    if self.afflatus_mode == nil then
        if buff_util.is_buff_active(buff_util.buff_id('Afflatus Misery')) then
            self:set_afflatus_mode(WhiteMage.Afflatus.Misery)
        else
            self:set_afflatus_mode(WhiteMage.Afflatus.Solace)
        end
    end
    return self.afflatus_mode
end

return WhiteMage