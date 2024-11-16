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

function RuneFencer:get_resistance_for_rune(rune, numRunes)
    numRunes = numRunes or self:get_max_num_runes()

    local job_point_bonus = 0
    if job_util.get_job_points(res.jobs[self.jobId].ens) >= 2100 then
        job_point_bonus = 20
    end

    local resistance = numRunes * (math.floor((49 * self:getLevel() / 99) + 5.5) + job_point_bonus)

    if rune == 'Lux' then
        return 7, resistance
    elseif rune == 'Tenebrae' then
        return 6, resistance
    elseif rune == 'Unda' then
        return 0, resistance
    elseif rune == 'Ignis' then
        return 1, resistance
    elseif rune == 'Gelus' then
        return 2, resistance
    elseif rune == 'Flabra' then
        return 3, resistance
    elseif rune == 'Tellus' then
        return 4, resistance
    elseif rune == 'Sulpor' then
        return 5, resistance
    end

    return 15, 0
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