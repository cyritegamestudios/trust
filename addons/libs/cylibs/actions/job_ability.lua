---------------------------
-- Action representing a job ability
-- @class module
-- @name JobAbility

require('coroutine')
require('vectors')
require('math')

local Action = require('cylibs/actions/action')
local JobAbility = setmetatable({}, {__index = Action })
JobAbility.__index = JobAbility

function JobAbility.new(x, y, z, job_ability_name, target_index)
    local self = setmetatable(Action.new(x, y, z), JobAbility)
    self.job_ability_name = job_ability_name
    self.target_index = target_index
    self:debug_log_create(self:gettype())
    return self
end

function JobAbility:destroy()
    Action.destroy(self)

    self:debug_log_destroy(self:gettype())
end

function JobAbility:can_perform()
    local job_abilities = player_util.get_job_abilities()
    if not job_abilities:contains(res.job_abilities:with('en', self.job_ability_name).id) then return false end

    return job_util.can_use_job_ability(self.job_ability_name)
end

function JobAbility:perform()
    if self.target_index == nil then
        windower.chat.input('/%s':format(self.job_ability_name))
    else
        local target = windower.ffxi.get_mob_by_index(self.target_index)
        if target then
            windower.chat.input('/'..self.job_ability_name..' '..target.id)
        end
    end

    coroutine.sleep(1)

    self:complete(true)
end

function JobAbility:get_job_ability_name()
    return self.job_ability_name
end

function JobAbility:gettype()
    return "jobabilityaction"
end

function JobAbility:getidentifier()
    return self.job_ability_name
end

function JobAbility:getrawdata()
    local res = {}

    res.jobability = {}
    res.jobability.x = self.x
    res.jobability.y = self.y
    res.jobability.z = self.z
    res.jobability.command = self:get_command()

    return res
end

function JobAbility:copy()
    return JobAbility.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_job_ability_name())
end

function JobAbility:is_equal(action)
    if action == nil then return false end

    return self:gettype() == action:gettype() and self:get_job_ability_name() == action:get_job_ability_name()
end

function JobAbility:tostring()
    return "JobAbility: %s":format(self:get_job_ability_name())
end

return JobAbility