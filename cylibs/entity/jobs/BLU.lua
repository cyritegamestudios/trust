---------------------------
-- Job file for Blue Mage.
-- @class module
-- @name BlueMage

local Job = require('cylibs/entity/jobs/job')
local BlueMage = setmetatable({}, {__index = Job })
BlueMage.__index = BlueMage

-------
-- Default initializer for a new Blue Mage.
-- @treturn BLU A Blue Mage
function BlueMage.new()
    local self = setmetatable(Job.new(), BlueMage)

    return self
end


return BlueMage