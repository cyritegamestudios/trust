---------------------------
-- Job file for Ranger.
-- @class module
-- @name Ranger

local Job = require('cylibs/entity/jobs/job')
local Ranger = setmetatable({}, {__index = Job })
Ranger.__index = Ranger

-------
-- Default initializer for a new Ranger.
-- @treturn RNG A Ranger
function Ranger.new()
    local self = setmetatable(Job.new('RNG'), Ranger)
    return self
end


return Ranger