---------------------------
-- Base class for a job.
-- @class module
-- @name Job

local Job = {}
Job.__index = Job

-------
-- Default initializer for a new Job.
-- @treturn Job A job
function Job.new()
    local self = setmetatable({}, Job)
    return self
end

-------
-- Default destroy function for a job.
function Job.destroy()
end

return Job