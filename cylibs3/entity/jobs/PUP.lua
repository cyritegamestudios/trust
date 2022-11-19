---------------------------
-- Job file for Puppetmaster.
-- @class module
-- @name Puppetmaster

local res = require('resources')

local Job = require('cylibs/entity/jobs/job')
local Puppetmaster = setmetatable({}, {__index = Job })
Puppetmaster.__index = Puppetmaster

-------
-- Default initializer for a new Puppetmaster.
-- @treturn PUP A Puppetmaster
function Puppetmaster.new()
    local self = setmetatable(Job.new(), Puppetmaster)
    return self
end

-------
-- Destroy function for a Puppetmaster.
function Puppetmaster:destroy()
    Job.destroy(self)
end

-------
-- Returns whether or not the Puppetmaster is currently overloaded.
-- @treturn Boolean True if the Puppetmaster is overloaded, and false otherwise.
function Puppetmaster:is_overloaded()
    return buff_util.is_buff_active(buff_util.buff_id('Overload'))
end

-------
-- Returns whether or not the Puppetmaster can use repair.
-- @treturn Boolean True if the Puppetmaster can use repair, and false otherwise.
function Puppetmaster:can_repair()
    if not job_util.can_use_job_ability('Repair') then
        return false
    end
    local item_id = windower.ffxi.get_items().equipment['ammo']
    if item_id and item_id ~= 0 then
        local item = res.items:with('id', item_id)
        if item then
            return item.en == 'Automat. Oil +3'
        end
    end
    return false
end

-------
-- Returns the Puppetmaster's active maneuvers, if any.
-- @treturn list Localized names of current maneuvers
function Puppetmaster:get_maneuvers()
    return L(windower.ffxi.get_player().buffs):map(function(buff_id)
        return res.buffs:with('id', buff_id).name
    end):filter(function(buff_name)
        return buff_name:contains('Maneuver')
    end)
end

-------
-- Returns the Puppetmaster's attachments.
-- @treturn list List of localized attachment names
function Puppetmaster:get_attachments()
    return pup_util.get_attachments()
end

return Puppetmaster