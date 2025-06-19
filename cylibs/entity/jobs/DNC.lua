---------------------------
-- Job file for Dancer.
-- @class module
-- @name Dancer

local Job = require('cylibs/entity/jobs/job')
local Dancer = setmetatable({}, {__index = Job })
Dancer.__index = Dancer

local buff_util = require('cylibs/util/buff_util')

-------
-- Default initializer for a new Dancer.
-- @tparam T cure_settings Cure thresholds
-- @treturn Dancer A Dancer
function Dancer.new(cure_settings)
    local self = setmetatable(Job.new('DNC'), Dancer)
    return self
end

-------
-- Returns the spell that can raise a party member.
-- @treturn Spell Raise spell
function Dancer:get_raise_spell()
    return nil
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