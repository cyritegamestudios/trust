---------------------------
-- Job file for RuneFencer.
-- @class module
-- @name RuneFencer

local Job = require('cylibs/entity/jobs/job')
local RuneFencer = setmetatable({}, {__index = Job })
RuneFencer.__index = RuneFencer

local rune_list = L{
    'Ignis',
    'Gelus',
    'Flabra',
    'Tellus',
    'Sulpor',
    'Unda',
    'Lux',
    'Tenebrae'
}

-------
-- Default initializer for a new RuneFencer.
-- @treturn RuneFencer A RuneFencer
function RuneFencer.new()
    local self = setmetatable(Job.new('RUN'), RuneFencer)
    return self
end

-------
-- Returns the Rune Fencer's active runes, if any.
-- @treturn list Localized names of current runes
function RuneFencer:get_current_runes()
    return L(windower.ffxi.get_player().buffs):map(function(buff_id)
        return res.buffs:with('id', buff_id).en
    end):filter(function(buff_name)
        return rune_list:contains(buff_name)
    end)
end

-------
-- Returns the list of job abilities that can be used with the given rune.
-- @treturn list List of JobAbility
function RuneFencer:get_wards_for_rune(rune)
    local result = L{}
    if L{ 'Lux', 'Tenebrae', 'Unda', 'Ignis', 'Gelus', 'Flabra', 'Tellus', 'Sulpor'}:contains(rune) then
        local buffs = L{}
        for i = 1, self:get_max_num_runes() do
            buffs:append(rune)
        end
        local conditions = L{ HasBuffsCondition.new(buffs) }
        for ward_name in L{ 'Valiance', 'Vallation' }:it() do
            if job_util.knows_job_ability(job_util.job_ability_id(ward_name)) then
                local job_ability = JobAbility.new(ward_name, L{}:extend(conditions))
                result:append(job_ability)
            end
        end
    end
    return result
end

-------
-- Returns the maximum number of runes that can be used.
-- @treturn number Maximum number of runes
function RuneFencer:get_max_num_runes()
    local player = windower.ffxi.get_player()
    if player then
        if player.main_job_id == res.jobs:with('en', 'Rune Fencer').id then
            return 3
        else
            return 2
        end
    end
    return 3
end

return RuneFencer