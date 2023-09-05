---------------------------
-- Job file for Red Mage.
-- @class module
-- @name RedMage

local Job = require('cylibs/entity/jobs/job')
local RedMage = setmetatable({}, {__index = Job })
RedMage.__index = RedMage

local cure_util = require('cylibs/util/cure_util')

-------
-- Default initializer for a new Red Mage.
-- @tparam T cure_settings Cure thresholds
-- @treturn RDM A Red Mage
function RedMage.new(cure_settings)
    local self = setmetatable(Job.new(), RedMage)
    self:set_cure_settings(cure_settings)
    return self
end

-------
-- Returns the Spell for the cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Cure spell
function RedMage:get_cure_spell(hp_missing)
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
function RedMage:get_aoe_cure_spell(hp_missing)
    return nil
end

-------
-- Returns the spell that can raise a party member.
-- @treturn Spell Raise spell
function RedMage:get_raise_spell()
    return Buff.new('Raise')
end

-------
-- Returns the threshold below which players should be healed.
-- @tparam Boolean is_backup_healer Whether the player is the backup healer
-- @treturn number HP percentage
function RedMage:get_cure_threshold(is_backup_healer)
    if is_backup_healer then
        return self.cure_settings.Thresholds['Emergency'] or 40
    else
        return self.cure_settings.Thresholds['Default'] or 78
    end
end

-------
-- Returns the delay between cures.
-- @treturn number Delay between cures in seconds
function RedMage:get_cure_delay()
    return self.cure_settings.Delay or 2
end

-------
-- Sets the cure settings.
-- @tparam T cure_settings Cure settings
function RedMage:set_cure_settings(cure_settings)
    self.cure_settings = cure_settings or cure_util.default_cure_settings
end

return RedMage