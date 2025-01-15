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

-------
-- Returns whether a spell is known.
-- @tparam number spell_id Spell id (see res/spells.lua)
-- @treturn boolean True if the spell is known
function Job:knows_spell(spell_id)
    return self:get_spells(function(id)
        return spell_id == id
    end):length() > 0
end

-------
-- Returns a list of conditions for an ability.
-- @tparam Spell|JobAbility ability The ability
-- @treturn list List of conditions
function Job:get_conditions_for_ability(ability)
    local conditions = L{} + ability:get_conditions()
    if ability.requires_all_job_abilities ~= nil and ability:requires_all_job_abilities() and ability.get_job_abilities ~= nil then
        for job_ability_name in ability:get_job_abilities():it() do
            conditions = conditions + JobAbility.new(job_ability_name):get_conditions()
        end
    end
    return conditions
end

-------
-- Returns a list of known job abilities.
-- @tparam function filter Optional filter function
-- @treturn list List of known job ability ids
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
-- Returns whether a job ability is known.
-- @tparam number job_ability_id Job ability id (see res/job_abilities.lua)
-- @treturn boolean True if the job ability is known
function Job:knows_job_ability(job_ability_id)
    return self:get_job_abilities(function(id)
        return job_ability_id == id
    end):length() > 0
end

-------
-- Returns the job level.
-- @treturn number Job level.
function Job:getLevel()
    local player = windower.ffxi.get_player()
    if self:isMainJob() then
        return player.main_job_level
    else
        return player.sub_job_level
    end
end

-------
-- Returns whether this job is the main job or sub job.
-- @treturn boolean True if the job is the main job.
function Job:isMainJob()
    local player = windower.ffxi.get_player()
    return player.main_job_id == self.jobId
end

return Job