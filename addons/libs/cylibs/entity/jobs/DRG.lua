---------------------------
-- Job file for Dragoon.
-- @class module
-- @name Dragoon

local Job = require('cylibs/entity/jobs/job')
local Dragoon = setmetatable({}, {__index = Job })
Dragoon.__index = Dragoon

-------
-- Default initializer for a new Dragoon.
-- @treturn DRG A Dragoon
function Dragoon.new()
    local self = setmetatable(Job.new(), Dragoon)

    return self
end


return Dragoon