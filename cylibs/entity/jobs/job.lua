---------------------------
-- Base class for a job.
-- @class module
-- @name Job

local SpellList = require('cylibs/util/spell_list')

local Job = {}
Job.__index = Job

-------
-- Default initializer for a new Job.
-- @treturn Job A job
function Job.new(jobNameShort, spellWhitelist)
    local self = setmetatable({}, Job)
    self.jobNameShort = jobNameShort
    self.jobId = res.jobs:with('ens', jobNameShort).id
    self.spell_list = SpellList.new(self.jobId, self:getLevel(), spellWhitelist or L{})
    return self
end

-------
-- Default destroy function for a job.
function Job.destroy()
end

-------
-- Returns a list of known spell ids.
-- @tparam function filter Optional filter function
-- @treturn list List of known spell ids
function Job:get_spells(filter)
    filter = filter or function(_) return true end
    self.spell_list.jobLevel = self:getLevel()
    return self.spell_list:getKnownSpellIds():filter(function(spell_id)
        return filter(spell_id)
    end)
end

function Job:get_job_abilities(filter)
    filter = filter or function(_) return true end
    return player_util.get_job_abilities():filter(function(job_ability_id)
        if not job_util.knows_job_ability(job_ability_id, res.jobs:with('ens', self.jobNameShort).id) then
            return false
        end
        return filter(job_ability_id)
    end)
end

-------
-- Returns whether this job is the main job or sub job.
-- @treturn boolean True if the job is the main job.
function Job:getLevel()
    local player = windower.ffxi.get_player()

    local isMainJob = player.main_job_id == self.jobId
    if isMainJob then
        return player.main_job_level
    else
        return player.sub_job_level
    end
end

return Job