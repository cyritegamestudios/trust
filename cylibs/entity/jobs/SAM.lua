---------------------------
-- Job file for Samurai.
-- @class module
-- @name Samurai

local Job = require('cylibs/entity/jobs/job')
local Samurai = setmetatable({}, {__index = Job })
Samurai.__index = Samurai

-------
-- Default initializer for a new Samurai.
-- @treturn SAM A Samurai
function Samurai.new()
    local self = setmetatable(Job.new(), Samurai)

    return self
end


return Samurai