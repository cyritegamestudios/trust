---------------------------
-- Job file for Paladin.
-- @class module
-- @name Paladin

local Job = require('cylibs/entity/jobs/job')
local Paladin = setmetatable({}, {__index = Job })
Paladin.__index = Paladin

-------
-- Default initializer for a new Paladin.
-- @treturn PLD A Paladin
function Paladin.new()
    local self = setmetatable(Job.new('PLD'), Paladin)
    return self
end

-------
-- Returns all AOE spells.
-- @treturn list List of AOE spell names
function Paladin:get_aoe_spells()
    return L{ 'Banishga' }
end

return Paladin