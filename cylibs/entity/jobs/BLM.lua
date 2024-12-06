---------------------------
-- Job file for Black Mage.
-- @class module
-- @name BlackMage

local Job = require('cylibs/entity/jobs/job')
local BlackMage = setmetatable({}, {__index = Job })
BlackMage.__index = BlackMage

-------
-- Default initializer for a new BlackMage.
-- @treturn BlackMage A BlackMage
function BlackMage.new()
    local self = setmetatable(Job.new('BLM', L{ 'Dispelga', 'Impact' }), BlackMage)
    return self
end

-------
-- Returns all AOE spells.
-- @treturn list List of AOE spell names
function BlackMage:get_aoe_spells()
    return L{
        'Stonega', 'Stonega II', 'Stonega III', 'Stoneja',
        'Aeroga', 'Aeroga II', 'Aeroga III', 'Aeroja',
        'Blizzaga', 'Blizzaga II', 'Blizzaga III', 'Blizzaja',
        'Firaga', 'Firaga II', 'Firaga III', 'Firaja',
        'Waterga', 'Waterga II', 'Waterga III', 'Waterja',
        'Thundaga', 'Thundaga II', 'Thundaga III', 'Thundaja',
        'Meteor'
    }
end

return BlackMage