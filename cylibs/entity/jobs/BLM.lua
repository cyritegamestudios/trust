---------------------------
-- Job file for Black Mage.
-- @class module
-- @name BlackMage

local Job = require('cylibs/entity/jobs/job')
local BlackMage = setmetatable({}, {__index = Job })
BlackMage.__index = BlackMage

-------
-- Default initializer for a new BlackMage.
-- @treturn BlackMage A BlackMage
function BlackMage.new()
    local self = setmetatable(Job.new('BLM', L{ 'Dispelga', 'Impact' }), BlackMage)
    return self
end

-------
-- Returns all AOE spells.
-- @treturn list List of AOE spell names
function BlackMage:get_aoe_spells()
    return L{
        'Stonega', 'Stonega II', 'Stonega III', 'Stoneja',
        'Aeroga', 'Aeroga II', 'Aeroga III', 'Aeroja',
        'Blizzaga', 'Blizzaga II', 'Blizzaga III', 'Blizzaja',
        'Firaga', 'Firaga II', 'Firaga III', 'Firaja',
        'Waterga', 'Waterga II', 'Waterga III', 'Waterja',
        'Thundaga', 'Thundaga II', 'Thundaga III', 'Thundaja',
        'Meteor'
    }
end

-------
-- Returns a list of known job abilities.
-- @tparam function filter Optional filter function
-- @treturn list List of known job ability ids
function BlackMage:get_job_abilities(filter)
    local job_abilities = Job.get_job_abilities(self, filter)
    if res.jobs[windower.ffxi.get_player().sub_job_id].ens == 'SCH' then
        local sub_job_abilities = player_util.get_job_abilities():filter(function(job_ability_id)
            if not job_util.knows_job_ability(job_ability_id, res.jobs:with('ens', 'SCH').id) then
                return false
            end
            return filter(job_ability_id)
        end)
        job_abilities = (job_abilities + sub_job_abilities):unique()
    end
    return job_abilities
end

return BlackMage