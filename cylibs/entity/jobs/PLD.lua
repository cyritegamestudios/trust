---------------------------
-- Job file for Paladin.
-- @class module
-- @name Paladin

local Job = require('cylibs/entity/jobs/job')
local Paladin = setmetatable({}, {__index = Job })
Paladin.__index = Paladin

-------
-- Default initializer for a new Paladin.
-- @tparam T cure_settings Cure thresholds
-- @treturn PLD A Paladin
function Paladin.new(cure_settings)
    local self = setmetatable(Job.new(), Paladin)
    self.cure_settings = cure_settings
    return self
end

-------
-- Returns the Spell for the cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Cure spell
function Paladin:get_cure_spell(hp_missing)
    if hp_missing > 900 then
        return Spell.new('Cure IV', L{}, L{})
    elseif hp_missing > 600 then
        return Spell.new('Cure III', L{}, L{})
    else
        return nil
    end
end

-------
-- Returns the Spell for the aoe cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Aoe cure spell
function Paladin:get_aoe_cure_spell(hp_missing)
    return nil
end

-------
-- Returns the threshold below which players should be healed.
-- @tparam Boolean is_backup_healer Whether the player is the backup healer
-- @treturn number HP percentage
function Paladin:get_cure_threshold(is_backup_healer)
    if is_backup_healer then
        return self.cure_settings.Thresholds['Emergency'] or 25
    else
        return self.cure_settings.Thresholds['Default'] or 78
    end
end

-------
-- Returns the threshold above which AOE cures should be used.
-- @treturn number Minimum number of party members under cure threshold
function Paladin:get_aoe_threshold()
    return self.cure_settings.MinNumAOETargets or 3
end

-------
-- Returns the delay between cures.
-- @treturn number Delay between cures in seconds
function Paladin:get_cure_delay()
    return self.cure_settings.Delay or 2
end

return Paladin