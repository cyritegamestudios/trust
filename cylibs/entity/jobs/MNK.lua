---------------------------
-- Job file for Monk.
-- @class module
-- @name Monk

local Job = require('cylibs/entity/jobs/job')
local Monk = setmetatable({}, {__index = Job })
Monk.__index = Monk

-------
-- Default initializer for a new Monk.
-- @treturn MNK A Monk
function Monk.new()
    local self = setmetatable(Job.new('MNK'), Monk)
    return self
end


return Monk