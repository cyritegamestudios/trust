---------------------------
-- Condition base class.
-- @class module
-- @name Condition

local Condition = {}
Condition.__index = Condition

-------
-- Default initializer for a condition.
-- @treturn Condition A condition
function Condition.new()
    local self = setmetatable({
    }, Condition)

    return self
end

function Condition:destroy()
end

function Condition:is_satisfied()
    return true
end

return Condition



