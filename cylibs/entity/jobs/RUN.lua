---------------------------
-- Job file for RuneFencer.
-- @class module
-- @name RuneFencer

local Job = require('cylibs/entity/jobs/job')
local RuneFencer = setmetatable({}, {__index = Job })
RuneFencer.__index = RuneFencer

local rune_list = L{
    'Ignis',
    'Gelus',
    'Flabra',
    'Tellus',
    'Sulpor',
    'Unda',
    'Lux',
    'Tenebrae'
}

-------
-- Default initializer for a new RuneFencer.
-- @treturn RuneFencer A RuneFencer
function RuneFencer.new()
    local self = setmetatable(Job.new(), RuneFencer)

    return self
end

-------
-- Returns the Rune Fencer's active runes, if any.
-- @treturn list Localized names of current runes
function RuneFencer:get_current_runes()
    return L(windower.ffxi.get_player().buffs):map(function(buff_id)
        return res.buffs:with('id', buff_id).en
    end):filter(function(buff_name)
        return rune_list:contains(buff_name)
    end)
end

return RuneFencer