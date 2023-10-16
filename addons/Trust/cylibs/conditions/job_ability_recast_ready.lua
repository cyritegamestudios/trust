---------------------------
-- Condition checking whether a job ability's recast is ready.
-- @class module
-- @name JobAbilityRecastReadyCondition

local serializer_util = require('cylibs/util/serializer_util')
local job_util = require('cylibs/util/job_util')

local Condition = require('cylibs/conditions/condition')
local JobAbilityRecastReadyCondition = setmetatable({}, { __index = Condition })
JobAbilityRecastReadyCondition.__index = JobAbilityRecastReadyCondition

function JobAbilityRecastReadyCondition.new(job_ability_name)
    local self = setmetatable(Condition.new(), JobAbilityRecastReadyCondition)
    self.job_ability_name = job_ability_name
    return self
end

function JobAbilityRecastReadyCondition:is_satisfied(target_index)
    return job_util.knows_job_ability(job_util.job_ability_id(self.job_ability_name))
            and job_util.can_use_job_ability(self.job_ability_name)
end

function JobAbilityRecastReadyCondition:is_player_only()
    return true
end

function JobAbilityRecastReadyCondition:tostring()
    return "JobAbilityRecastReadyCondition"
end

function JobAbilityRecastReadyCondition:serialize()
    return "JobAbilityRecastReadyCondition.new(" .. serializer_util.serialize_args(self.job_ability_name) .. ")"
end

return JobAbilityRecastReadyCondition




