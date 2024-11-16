---------------------------
-- Job file for Warrior.
-- @class module
-- @name Warrior

local Job = require('cylibs/entity/jobs/job')
local Warrior = setmetatable({}, {__index = Job })
Warrior.__index = Warrior

-------
-- Default initializer for a new Warrior.
-- @treturn WAR A Warrior
function Warrior.new()
    local self = setmetatable(Job.new('WAR'), Warrior)

    return self
end


return Warrior