---------------------------
-- Job file for Ninja.
-- @class module
-- @name Ninja

local Job = require('cylibs/entity/jobs/job')
local Ninja = setmetatable({}, {__index = Job })
Ninja.__index = Ninja

-------
-- Default initializer for a new Ninja.
-- @treturn NIN A Ninja
function Ninja.new()
    local self = setmetatable(Job.new(), Ninja)

    return self
end


return Ninja