---------------------------
-- Job file for Thief.
-- @class module
-- @name Thief

local Job = require('cylibs/entity/jobs/job')
local Thief = setmetatable({}, {__index = Job })
Thief.__index = Thief

-------
-- Default initializer for a new Thief.
-- @treturn THF A Thief
function Thief.new()
    local self = setmetatable(Job.new('THF'), Thief)
    return self
end


return Thief